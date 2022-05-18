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

# module "msftcerts" {
#   source = "github.com/jacobnosal/terraform-acme-msftcerts.git?ref=v0.0.2"

#   registration_email    = var.registration_email
#   dns_name              = var.dns_name
#   azure_client_id       = var.azure_client_id
#   azure_client_secret   = var.azure_client_secret
#   azure_resource_group  = var.azure_resource_group
#   azure_subscription_id = var.azure_subscription_id
#   azure_tenant_id       = var.azure_tenant_id
#   azure_zone_name       = var.azure_zone_name
# }

module "waf-policies" {
  source = "./waf_policy"
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location

  tags = var.tags
}

###########################################################
# KeyVault Configuration
###########################################################
# resource "random_pet" "kv-name" {
#   prefix    = "kv"
#   separator = ""
#   length    = 3
# }

# resource "azurerm_key_vault" "kv" {
#   name                = substr(random_pet.kv-name.id, 0, 24)
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   tenant_id           = data.azurerm_client_config.current.tenant_id
#   sku_name            = "premium"

#   access_policy {
#     tenant_id = data.azurerm_client_config.current.tenant_id
#     object_id = data.azurerm_client_config.current.object_id

#     certificate_permissions = [
#       "Create",
#       "Delete",
#       "Get",
#       "Import",
#       "List",
#       "Update",
#       "Purge"
#     ]
#   }

#   access_policy {
#     tenant_id = data.azurerm_client_config.current.tenant_id
#     object_id = azurerm_user_assigned_identity.app-gw-id.principal_id

#     certificate_permissions = ["Get", "Purge"]
#     secret_permissions      = ["Get", "Purge"]
#   }
# }

# resource "azurerm_key_vault_certificate" "api-jacobnosal-com-frontend-ssl" {
#   name         = "api-jacobnosal-com-frontend-ssl"
#   key_vault_id = azurerm_key_vault.kv.id

#   certificate {
#     contents = module.msftcerts.pfx
#     password = module.msftcerts.pfx_password
#   }

#   certificate_policy {
#     issuer_parameters {
#       name = "Unknown"
#     }

#     key_properties {
#       exportable = true
#       key_size   = 2048
#       key_type   = "RSA"
#       reuse_key  = false
#     }

#     secret_properties {
#       content_type = "application/x-pkcs12"
#     }
#   }
# }

###########################################################
# Network Configuration
###########################################################
resource "azurerm_virtual_network" "test" {
  name                = var.virtual_network_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
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
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  #   domain_name_label = ""

  tags = var.tags
}

# TODO: parameterize this
resource "azurerm_dns_a_record" "api_jacobnosal_com" {
  name                = "api"
  zone_name           = "jacobnosal.com"
  resource_group_name = "jacobnosal.com-dns"
  ttl                 = 300
  target_resource_id  = azurerm_public_ip.pip.id
}

###########################################################
# Application Gateway Configuration
###########################################################
resource "azurerm_application_gateway" "network" {
  name                = var.app_gateway_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

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
    # host_name                      = "api.jacobnosal.com"
    # ssl_certificate_name           = "api-jacobnosal-com-frontend-ssl"
    # require_sni                    = true
    # ssl_profile_name               = "api.jacobnosal.com-ssl-policy"
  }

  ssl_profile {
    name = "api.jacobnosal.com-ssl-policy"
    # This is for mutual authentication with clients.
    # trusted_client_certificate_names = ""
    verify_client_cert_issuer_dn = false
    ssl_policy {
      disabled_protocols   = ["TLSv1_0", "TLSv1_1"]
      min_protocol_version = "TLSv1_2"
    }
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }

  # rewrite rule sets need to be associated with a path map
  # need to configure an https listener and figure the cert stuff (.pfx)
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

  # waf_configuration {
  #   enabled              = true
  #   firewall_mode        = "Prevention"
  #   rule_set_type        = "OWASP"
  #   rule_set_version     = "3.2"
  #   file_upload_limit_mb = 128
  #   request_body_check   = true
  # }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app-gw-id.id]
  }

  # ssl_certificate {
  #   name                = "api-jacobnosal-com-frontend-ssl"
  #   key_vault_secret_id = azurerm_key_vault_certificate.api-jacobnosal-com-frontend-ssl.secret_id
  # }

  tags = var.tags
}

# This doesn't behave correctly. Moving it to an install script.
# resource "null_resource" "trusted_root_cert" {
#   # triggers = {
#   #   app_gw_id = azurerm_application_gateway.network.id
#   # }

#   provisioner "local-exec" {
#     command = <<EOF
#       az network application-gateway root-cert create \
#         --cert-file keys/${var.dns_name}.trusted_root_cert.cer  \
#         --gateway-name ${azurerm_application_gateway.network.name}  \
#         --name ${var.dns_name}-trusted-root-cert \
#         --resource-group ${azurerm_resource_group.rg.name}
#     EOF
#   }
# }

###########################################################
# AKS Configuration
###########################################################
resource "azurerm_kubernetes_cluster" "k8s" {
  name       = var.aks_name
  location   = azurerm_resource_group.rg.location
  dns_prefix = var.aks_dns_prefix

  resource_group_name = azurerm_resource_group.rg.name

  http_application_routing_enabled = false

  linux_profile {
    admin_username = var.vm_user_name

    ssh_key {
      key_data = file(var.public_ssh_key_path)
    }
  }

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

# ###########################################################
# # Log and Metric Configuration
# ###########################################################
# resource "random_pet" "log-analytics-name" {
#   separator = ""
#   length    = 10
# }

# resource "azurerm_log_analytics_workspace" "app-gw-demo" {
#   name                = substr(random_pet.log-analytics-name.id, 0, 63)
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   sku                 = "PerGB2018"
#   retention_in_days   = 30
# }

# # app gateway
# resource "azurerm_monitor_diagnostic_setting" "example" {
#   name                       = "app-gw-diag-settings-${azurerm_application_gateway.network.name}"
#   target_resource_id         = azurerm_application_gateway.network.id
#   log_analytics_workspace_id = azurerm_log_analytics_workspace.app-gw-demo.id

#   log {
#     category = "ApplicationGatewayAccessLog"

#     retention_policy {
#       enabled = true
#       days    = 30
#     }
#   }

#   log {
#     category = "ApplicationGatewayPerformanceLog"

#     retention_policy {
#       enabled = true
#       days    = 30
#     }
#   }

#   log {
#     category = "ApplicationGatewayFirewallLog"

#     retention_policy {
#       enabled = true
#       days    = 30
#     }
#   }

#   metric {
#     category = "AllMetrics"

#     retention_policy {
#       enabled = true
#       days    = 30
#     }
#   }
# }

# # k8s cluster
# resource "azurerm_monitor_diagnostic_setting" "k8s" {
#   name                       = "k8s-diag-settings-${azurerm_kubernetes_cluster.k8s.name}"
#   target_resource_id         = azurerm_kubernetes_cluster.k8s.id
#   log_analytics_workspace_id = azurerm_log_analytics_workspace.app-gw-demo.id

#   dynamic "log" {
#     for_each = toset(var.k8s_log_categories)
#     iterator = category
#     content {
#       category = category.value

#       retention_policy {
#         enabled = true
#         days    = 30
#       }
#     }
#   }

#   metric {
#     category = "AllMetrics"

#     retention_policy {
#       enabled = true
#       days    = 30
#     }
#   }
# }