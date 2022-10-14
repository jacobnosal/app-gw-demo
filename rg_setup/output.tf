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

output "client_id" {
  value = var.aks_service_principal_app_id
}