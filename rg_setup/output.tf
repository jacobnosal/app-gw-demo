output "aks_rbac_enabled" {
  value = azurerm_kubernetes_cluster.k8s.role_based_access_control_enabled
}

output "subscription_id" {
  value = data.azurerm_client_config.current.subscription_id
}

output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "identity_resource_id" {
  value = azurerm_user_assigned_identity.app-gw-id.id
}

output "identity_client_id" {
  value = azurerm_user_assigned_identity.app-gw-id.client_id
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