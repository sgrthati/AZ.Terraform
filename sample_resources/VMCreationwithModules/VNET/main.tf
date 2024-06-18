resource "azurerm_virtual_network" "VNET" {
  name                = var.VNET_name
  address_space       = ["10.1.0.0/16"]
  location            = var.location
  resource_group_name = var.RG_name

}
resource "azurerm_subnet" "SUBNET1" {
  name                 = "mySubnet"
  resource_group_name  = var.RG_name
  virtual_network_name = azurerm_virtual_network.VNET.name
  address_prefixes       = ["10.1.1.0/24"]
}
resource "azurerm_public_ip" "PIP" {
  name                = "PIP-1"
  location            = var.location
  resource_group_name = var.RG_name
  allocation_method   = "Static"
}
resource "azurerm_network_security_group" "NSG" {
  name                = "myNetworkSecurityGroup"
  location            = var.location
  resource_group_name = var.RG_name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
resource "azurerm_network_interface" "NIC" {
  name                = "SRI-NIC"
  location            = var.location
  resource_group_name = var.RG_name

  ip_configuration {
    name                          = "IPCONFIG1"
    subnet_id                     = "${azurerm_subnet.SUBNET1.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = "${azurerm_public_ip.PIP.id}"
  }
}
