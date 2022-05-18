data "azurerm_client_config" "current" {}

# data "azurerm_key_vault" "kv" {
#   name                = azurerm_key_vault.kv.name
#   resource_group_name = azurerm_key_vault.kv.resource_group_name
# }

data "azurerm_subnet" "kubesubnet" {
  name                 = var.aks_subnet_name
  virtual_network_name = azurerm_virtual_network.test.name
  resource_group_name  = azurerm_resource_group.rg.name
  depends_on           = [azurerm_virtual_network.test]
}

data "azurerm_subnet" "appgwsubnet" {
  name                 = local.app_gateway_subnet_name
  virtual_network_name = azurerm_virtual_network.test.name
  resource_group_name  = azurerm_resource_group.rg.name
  depends_on           = [azurerm_virtual_network.test]
}