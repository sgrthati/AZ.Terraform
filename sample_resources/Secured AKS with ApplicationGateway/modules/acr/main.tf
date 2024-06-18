resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = var.acr_rg
  location            = var.location
  sku                 = "Standard"
  admin_enabled       = false
}