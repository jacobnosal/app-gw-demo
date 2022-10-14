data "azurerm_client_config" "current" {}

data "azurerm_subnet" "kubesubnet" {
  name                 = var.aks_subnet_name
  virtual_network_name = azurerm_virtual_network.test.name
  resource_group_name  = data.azurerm_resource_group.rg.name
  depends_on           = [azurerm_virtual_network.test]
}

data "azurerm_subnet" "appgwsubnet" {
  name                 = local.app_gateway_subnet_name
  virtual_network_name = azurerm_virtual_network.test.name
  resource_group_name  = data.azurerm_resource_group.rg.name
  depends_on           = [azurerm_virtual_network.test]
}

data "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# User Assigned Identities 
data "azurerm_user_assigned_identity" "app-gw-id" {
  resource_group_name = data.azurerm_resource_group.rg.name
  name                = var.managed_identity_name
}