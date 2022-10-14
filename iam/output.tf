output "app_gateway_identity_name" {
  value = azurerm_user_assigned_identity.app-gw-id.name
}

output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "gateway_resource_group_name" {
  value = azurerm_resource_group.gtw_rg.name
}