provider "azurerm" {
  features {}
}

module "naming" {
  source  = "Azure/naming/azurerm"
  suffix = [ "demo" ]
  prefix = [ "iam" ]
}

module "naming_gtw" {
  source  = "Azure/naming/azurerm"
  suffix = [ "demo" ]
  prefix = [ "gtw" ]
}

resource "azurerm_resource_group" "rg" {
  name     = module.naming.resource_group.name
  location = var.location

  tags = var.tags
}

resource "azurerm_resource_group" "gtw_rg" {
  name     = module.naming_gtw.resource_group.name
  location = var.location

  tags = var.tags
}