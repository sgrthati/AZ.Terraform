data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}
locals {
  resource_group_name = "${data.azurerm_resource_group.main.name}"
  dns_name = "${var.dns_name != "" ? var.dns_name : "${data.azurerm_resource_group.main.name}-pv-dns"}"
  dns_asc_name = "${data.azurerm_resource_group.main.name}-pv-dns-asc"
  tags = "${merge(
    data.azurerm_resource_group.main.tags,
    var.tags
  )}"
}

resource "azurerm_private_dns_zone" "private_dns_zone" {
  count = var.dns_enabled == true ? 1 : 0
  name                = local.dns_name
  resource_group_name = local.resource_group_name
}

# Resource-2: Associate Private DNS Zone to Virtual Network
resource "azurerm_private_dns_zone_virtual_network_link" "private_dns_zone_vnet_associate" {
  count                 = var.dns_enabled == true ? 1 : 0
  name                  = local.dns_asc_name
  resource_group_name   = local.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_zone[0].name
  virtual_network_id    = var.dns_vnet_id
}