terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.97.0"
    }
  }
}

provider "azurerm" {
  features {}

}
resource "azurerm_resource_group" "RG" {
  name = var.name
  location = var.location
  
}
module "VNET" {
  source = "./VNET"
  VNET_name = var.vnet
  RG_name  = azurerm_resource_group.RG.name
  location = azurerm_resource_group.RG.location
}
module "VM" {
  source = "./VM"
  RG_name  = azurerm_resource_group.RG.name
  location = azurerm_resource_group.RG.location
  VM_name = "SRI"
  NIC = "${module.VNET.NIC}"

}
