terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.0.0"
    }
  }
}
data "azurerm_client_config" "current" {}
# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
  subscription_id = data.azurerm_client_config.current.subscription_id
}
provider "azuread" {}