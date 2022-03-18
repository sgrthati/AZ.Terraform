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

  subscription_id = "aaca85ab-ad78-4c79-8102-031f7ae1a0dc"
  client_id       = "910d9557-1911-41eb-9fea-9a5353486bb5"
  client_secret   = "shA7Q~wgujZyHE0lWjYRl8CD4XSy1n1Lf5H_w"
  tenant_id       = "af794339-2fdc-421d-ac0a-f3824494051e"
}
resource "azurerm_resource_group" "RG1" {
  name     = "srisagar"
  location = "East US"
}
resource "azurerm_network_security_group" "NSG" {
    name = "Sagar-NSG"
    location = azurerm_resource_group.RG1.location
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
  name                = "SAGAR-VNET"
  location            = azurerm_resource_group.RG1.location
  resource_group_name = azurerm_resource_group.RG1.name
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["10.0.0.4", "10.0.0.5"]
}
resource "azurerm_subnet" "SUBNET1" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.RG1.name
  virtual_network_name = azurerm_virtual_network.VNET.name
  address_prefixes      = ["10.0.2.0/24"]
}
resource "azurerm_public_ip" "PIP" {
  name                = "SAGAR-PIP"
  resource_group_name = azurerm_resource_group.RG1.name
  location            = azurerm_resource_group.RG1.location
  allocation_method   = "Static"
}
resource "azurerm_network_interface" "NIC" {
  name                = "SAGAR-NIC"
  location            = azurerm_resource_group.RG1.location
  resource_group_name = azurerm_resource_group.RG1.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.SUBNET1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.PIP.id
  }
}
resource "azurerm_windows_virtual_machine" "VM1" {
  name                = "SAGARVM"
  resource_group_name = azurerm_resource_group.RG1.name
  location            = azurerm_resource_group.RG1.location
  size                = "Standard_B1s"
  admin_username      = "SAGAR.THATI"
  admin_password      = "AZURE@123456"
  network_interface_ids = [
    azurerm_network_interface.NIC.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}
