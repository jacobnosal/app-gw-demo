provider "azurerm" {
  features {}
}

locals {
  backend_address_pool_name      = "${azurerm_virtual_network.test.name}-beap"
  frontend_port_name             = "${azurerm_virtual_network.test.name}-feport"
  frontend_ip_configuration_name = "${azurerm_virtual_network.test.name}-feip"
  http_setting_name              = "${azurerm_virtual_network.test.name}-be-htst"
  listener_name                  = "${azurerm_virtual_network.test.name}-httpslstn"
  request_routing_rule_name      = "${azurerm_virtual_network.test.name}-rqrt"
  app_gateway_subnet_name        = "appgwsubnet"
}

module "waf-policies" {
  source = "./waf_policy"
}

###########################################################
# Network Configuration
###########################################################
resource "azurerm_virtual_network" "test" {
  name                = var.virtual_network_name
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  address_space       = [var.virtual_network_address_prefix]

  subnet {
    name           = var.aks_subnet_name
    address_prefix = var.aks_subnet_address_prefix
  }

  subnet {
    name           = local.app_gateway_subnet_name
    address_prefix = var.app_gateway_subnet_address_prefix
  }

  tags = var.tags
}

# Public Ip 
resource "azurerm_public_ip" "pip" {
  name                = "publicIp1"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = var.tags
}

resource "azurerm_dns_a_record" "api_jacobnosal_com" {
  name                = "api"
  zone_name           = var.azure_dns_zone_name
  resource_group_name = var.azure_dns_resource_group
  ttl                 = 300
  target_resource_id  = azurerm_public_ip.pip.id
}

###########################################################
# Application Gateway Configuration
###########################################################
resource "azurerm_application_gateway" "network" {
  name                = var.app_gateway_name
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location

  # Terraform , by default, assumes that it is the sole management agent of the
  # resources in this configuration. In this instance, we are deploying the
  # Application Gateway Ingress Controller (AGIC) to the AKS cluster and AGIC
  # creates and updates various subresources in App Gateway. Terraform will
  # generate a plan to overwrite these and, if the plan is applied, all of the
  # apps lose their ingress routing (and user connectivity!). We can configure
  # the lifecycle argument of the app gateway resource to ignore chnages in the
  # subresources that we expect AGIC to manage.
  lifecycle {
    ignore_changes = [
      backend_address_pool,
      backend_http_settings,
      frontend_port,
      http_listener,
      probe,
      redirect_configuration,
      request_routing_rule,
      ssl_certificate,
      tags,
      url_path_map,
    ]
  }

  sku {
    name     = var.app_gateway_sku
    tier     = var.app_gateway_tier
    capacity = 4
  }

  gateway_ip_configuration {
    name      = "appGatewayIpConfig"
    subnet_id = data.azurerm_subnet.appgwsubnet.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.pip.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 1
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20220101S"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }

  rewrite_rule_set {
    name = "app-a-rewrite-rule-set"

    rewrite_rule {
      name          = "strip-base-path"
      rule_sequence = "100"
      url {
        path = "/{var_uri_path_2}"
      }
      condition {
        variable    = "var_uri_path"
        pattern     = "/app-a(/|$)(.*)"
        ignore_case = true
        negate      = false
      }
    }
  }

  rewrite_rule_set {
    name = "app-b-rewrite-rule-set"

    rewrite_rule {
      name          = "strip-base-path"
      rule_sequence = "100"
      url {
        path = "/{var_uri_path_2}"
      }
      condition {
        variable    = "var_uri_path"
        pattern     = "/app-b(/|$)(.*)"
        ignore_case = true
        negate      = false
      }
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [data.azurerm_user_assigned_identity.app-gw-id.id]
  }

  tags = var.tags
}

###########################################################
# AKS Configuration
###########################################################
resource "azurerm_kubernetes_cluster" "k8s" {
  name       = var.aks_name
  location   = data.azurerm_resource_group.rg.location
  dns_prefix = var.aks_dns_prefix

  resource_group_name = data.azurerm_resource_group.rg.name

  http_application_routing_enabled = false

  # linux_profile {
  #   admin_username = var.vm_user_name

  #   ssh_key {
  #     key_data = file(var.public_ssh_key_path)
  #   }
  # }

  default_node_pool {
    name            = "agentpool"
    node_count      = var.aks_agent_count
    vm_size         = var.aks_agent_vm_size
    os_disk_size_gb = var.aks_agent_os_disk_size
    vnet_subnet_id  = data.azurerm_subnet.kubesubnet.id
  }

  service_principal {
    client_id     = var.aks_service_principal_app_id
    client_secret = var.aks_service_principal_client_secret
  }

  network_profile {
    network_plugin     = "azure"
    dns_service_ip     = var.aks_dns_service_ip
    docker_bridge_cidr = var.aks_docker_bridge_cidr
    service_cidr       = var.aks_service_cidr
  }

  role_based_access_control_enabled = var.aks_enable_rbac

  tags = var.tags
}