# User Assigned Identities 
resource "azurerm_user_assigned_identity" "app-gw-id" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  name = "ApplicationGatewayIdentity"

  tags = var.tags
}

resource "azurerm_role_assignment" "sp-Network-Contributor-kubesubnet" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Network Contributor"
  principal_id         = var.aks_service_principal_object_id
}

resource "azurerm_role_assignment" "sp-Managed-Identity-Operator-app-gw-id" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = var.aks_service_principal_object_id
}

resource "azurerm_role_assignment" "app-gw-id-Contributor-app-gw" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.app-gw-id.principal_id
}

resource "azurerm_role_assignment" "app-gw-id-Reader" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.app-gw-id.principal_id
}