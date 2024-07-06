data "azurerm_resource_group" "main" {
  name = "${var.resource_group_name}"
}

locals {
  resource_group_name = "${data.azurerm_resource_group.main.name}"
  location            = "${var.location != "" ? var.location : data.azurerm_resource_group.main.location}"
  VNET_name = "${var.VNET_name != "" ? var.VNET_name : "${var.resource_group_name}-vnet"}"
  subnet_name = "${var.subnet_name != "" ? var.subnet_name : "${var.resource_group_name}-vnet-subnet"}"
  nsg_name = "${var.nsg_name != "" ? var.nsg_name : "${var.resource_group_name}-vnet-nsg"}"
}

resource "azurerm_virtual_network" "VNET" {
  name                = local.VNET_name
  address_space       = ["10.1.0.0/16"]
  location            = local.location
  resource_group_name = local.resource_group_name

}
resource "azurerm_subnet" "SUBNET1" {
  name                 = local.subnet_name
  resource_group_name  = local.resource_group_name
  virtual_network_name = azurerm_virtual_network.VNET.name
  address_prefixes       = ["10.1.1.0/24"]
}

resource "azurerm_network_security_group" "NSG" {       
  name                = local.nsg_name
  location            = local.location
  resource_group_name = local.resource_group_name

  dynamic "security_rule" {
    for_each = var.allowed_inbound_ports
    content {
      name                       = security_rule.key
      priority                   = security_rule.value.priority
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = security_rule.value.port
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association" {
  subnet_id                 = azurerm_subnet.SUBNET1.id
  network_security_group_id = azurerm_network_security_group.NSG.id
}