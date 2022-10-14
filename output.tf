output "aks_rbac_enabled" {
  value = azurerm_kubernetes_cluster.k8s.role_based_access_control_enabled
}

output "subscription_id" {
  value = data.azurerm_client_config.current.subscription_id
}

output "resource_group_name" {
  value = data.azurerm_resource_group.rg.name
}

output "client_key" {
  value     = azurerm_kubernetes_cluster.k8s.kube_config.0.client_key
  sensitive = true
}

output "client_certificate" {
  value     = azurerm_kubernetes_cluster.k8s.kube_config.0.client_certificate
  sensitive = true
}

output "cluster_ca_certificate" {
  value     = azurerm_kubernetes_cluster.k8s.kube_config.0.cluster_ca_certificate
  sensitive = true
}

output "cluster_username" {
  value     = azurerm_kubernetes_cluster.k8s.kube_config.0.username
  sensitive = true
}

output "cluster_password" {
  value     = azurerm_kubernetes_cluster.k8s.kube_config.0.password
  sensitive = true
}

output "cluster_name" {
  value = azurerm_kubernetes_cluster.k8s.name
}

output "kube_config" {
  value     = azurerm_kubernetes_cluster.k8s.kube_config_raw
  sensitive = true
}

output "host" {
  value     = azurerm_kubernetes_cluster.k8s.kube_config.0.host
  sensitive = true
}

output "application_ip_address" {
  value = azurerm_public_ip.pip.ip_address
}

output "application_domain_name" {
  value = azurerm_public_ip.pip.fqdn
}

output "application_gateway_name" {
  value = azurerm_application_gateway.network.name
}

output "registration_email" {
  value = var.registration_email
}

output "tenant_id" {
  value = var.azure_tenant_id
}

output "dns_resource_group_name" {
  value = var.azure_dns_resource_group
}

output "dns_zone_name" {
  value = var.azure_dns_zone_name
}

output "client_id" {
  value = var.aks_service_principal_app_id
}