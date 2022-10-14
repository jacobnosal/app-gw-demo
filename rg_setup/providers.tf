terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.4.0"
    }
  }

  backend "s3" {
    bucket = "tfstate-jnosal"
    key    = "app-gw-demo--rg-setup/terraform.tfstate"
    region = "us-west-2"
  }

  required_version = ">= 0.14"
}