terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.97.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}

  subscription_id = "000000000000000000000000000000000000"
  client_id       = "000000000000000000000000000000000000"
  client_secret   = "000000000000000000000000000000000000"
  tenant_id       = "000000000000000000000000000000000000"
}
resource "azurerm_resource_group" "RG1" {
  name     = var.resource_groups
  location = var.location
}
resource "azurerm_network_security_group" "NSG" {
  name                = var.NSG
  location            = azurerm_resource_group.RG1.location
  resource_group_name = azurerm_resource_group.RG1.name
  security_rule {
    name                       = "allow RDP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow HTTP"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
resource "azurerm_virtual_network" "VNET" {
  name                = var.VNET
  location            = azurerm_resource_group.RG1.location
  resource_group_name = azurerm_resource_group.RG1.name
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["10.0.0.4", "10.0.0.5"]
}
resource "azurerm_subnet" "SUBNET1" {
  name                 = var.subnet
  resource_group_name  = azurerm_resource_group.RG1.name
  virtual_network_name = azurerm_virtual_network.VNET.name
  address_prefixes     = ["10.0.2.0/24"]
}
resource "azurerm_virtual_network_dns_servers" "DNS" {
  virtual_network_id = azurerm_virtual_network.VNET.id
  dns_servers        = ["8.8.8.8", "168.63.129.16"]
}
resource "azurerm_public_ip" "PIP" {
  count               = var.VMcount
  name                = "publicIP-${count.index}"
  resource_group_name = azurerm_resource_group.RG1.name
  location            = azurerm_resource_group.RG1.location
  allocation_method   = "Static"
}
resource "azurerm_network_interface" "NIC" {
  count               = var.VMcount
  name                = "NIC-${count.index}"
  location            = azurerm_resource_group.RG1.location
  resource_group_name = azurerm_resource_group.RG1.name

  ip_configuration {
    name                          = "IPCONFIG1"
    subnet_id                     = azurerm_subnet.SUBNET1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.PIP[count.index].id}"
  }
}
resource "azurerm_linux_virtual_machine" "VM" {
  count               = var.VMcount
  name                = "SRIVM-${count.index}"
  resource_group_name = azurerm_resource_group.RG1.name
  location            = azurerm_resource_group.RG1.location
  size                = "Standard_B1s"
  admin_username      = "SAGAR.THATI"
  admin_password      = "AZURE@123456"
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.NIC[count.index].id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}
resource "azurerm_virtual_machine_extension" "Scripting" {
  name                       = var.VM
  count                      = var.VMcount
  virtual_machine_id         = "${azurerm_linux_virtual_machine.VM[count.index].id}"
  publisher                  = "Microsoft.Azure.Extensions"
  type                       = "CustomScript"
  type_handler_version       = "2.1"
  auto_upgrade_minor_version = true


  protected_settings = <<PROTECTED_SETTINGS
    {
            "commandToExecute": "sh java.sh",
            "storageAccountName": "${var.StorageAccountName}",
            "storageAccountKey": "${var.StorgaeAccountKey}",
            "fileUris": [
                "${var.FileUri}"
            ]
    }
  PROTECTED_SETTINGS
}
