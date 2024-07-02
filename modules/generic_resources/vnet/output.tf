output "subnet_id" {
  value = azurerm_subnet.SUBNET1.id
}
output "vnet_id" {
    value = azurerm_virtual_network.VNET.id
}