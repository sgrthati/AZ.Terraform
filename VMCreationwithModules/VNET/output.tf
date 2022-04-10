output "VNET_name" {
    value = [azurerm_virtual_network.VNET.name]
}
output "VNET_address_space" {
    value = [azurerm_virtual_network.VNET.address_space]
}
output "VNET_PIP" {
    value = [azurerm_public_ip.PIP.id]
}
output "VNET_SN" {
    value = [azurerm_subnet.SUBNET1.address_prefixes]
}
output "NIC" {
    value = [azurerm_network_interface.NIC.id]
}