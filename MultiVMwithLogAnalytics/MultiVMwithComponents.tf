terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.66.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}
resource "azurerm_resource_group" "RG1" {
  name     = var.resource_groups
  location = var.location
}
resource "azurerm_user_assigned_identity" "me" {
  resource_group_name      = azurerm_resource_group.RG1.name
  location                 = azurerm_resource_group.RG1.location
  name                     = "Moniter-me"
}
resource "azurerm_role_assignment" "mi-ra" {
  for_each             = toset(var.VMcount)
  scope                = azurerm_linux_virtual_machine.VM[each.key].id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = azurerm_user_assigned_identity.me.principal_id
  depends_on           = [
    azurerm_linux_virtual_machine.VM
  ]
}
resource "azurerm_network_security_group" "NSG" {
    name = var.NSG
    location =  azurerm_resource_group.RG1.location
    resource_group_name = azurerm_resource_group.RG1.name
}
resource "azurerm_virtual_network" "VNET" {
  name                = var.VNET
  location            = azurerm_resource_group.RG1.location
  resource_group_name = azurerm_resource_group.RG1.name
  address_space       = ["10.0.0.0/16"]
}
resource "azurerm_subnet" "SUBNET1" {
  name                 = var.subnet
  resource_group_name  = azurerm_resource_group.RG1.name
  virtual_network_name = azurerm_virtual_network.VNET.name
  address_prefixes      = ["10.0.2.0/24"]
}
resource "azurerm_public_ip" "PIP" {
  for_each            = toset(var.VMcount)
  name                = "publicIP-${each.value}"
  resource_group_name = azurerm_resource_group.RG1.name
  location            = azurerm_resource_group.RG1.location
  allocation_method   = "Static"
}
resource "azurerm_network_interface" "NIC" {
  for_each            = toset(var.VMcount)
  name                = "NIC-${each.value}"
  location            = azurerm_resource_group.RG1.location
  resource_group_name = azurerm_resource_group.RG1.name

  ip_configuration {
    name                          = "IPCONFIG1"
    subnet_id                     = azurerm_subnet.SUBNET1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.PIP[each.key].id
  }
}
#  Create NSG Rules
## Locals Block for Security Rules
locals {
  allowed_ports = {
    "100" : "80", # If the key starts with a number, you must use the colon syntax ":" instead of "="
    "110" : "443",
    "120" : "22"
  } 
}
## NSG Inbound Rule
resource "azurerm_network_security_rule" "nsg_inbound_rule" {
  for_each = local.allowed_ports
  name                        = "Rule-Port-${each.value}"
  priority                    = each.key
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = each.value 
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.RG1.name
  network_security_group_name = azurerm_network_security_group.NSG.name
}
resource "azurerm_network_interface_security_group_association" "nsg_association" {
  for_each                    = toset(var.VMcount)
  depends_on                  = [ azurerm_network_security_rule.nsg_inbound_rule ]
  network_interface_id        = azurerm_network_interface.NIC[each.key].id
  network_security_group_id   = azurerm_network_security_group.NSG.id
}
resource "azurerm_linux_virtual_machine" "VM" {
  for_each            = toset(var.VMcount)
  name                = "SRIVM-${each.value}"
  resource_group_name = azurerm_resource_group.RG1.name
  location            = azurerm_resource_group.RG1.location
  size                = "Standard_B1s"
  admin_username      = "adminuser" 
  network_interface_ids = [
    azurerm_network_interface.NIC[each.key].id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.me.id ]
  }

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("C:/Users/sri/.ssh/id_rsa.pub")
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}
#Azure moniter agent for linux
resource "azurerm_virtual_machine_extension" "AzureMonitorLinuxAgent" {
  for_each                   = toset(var.VMcount)
  name                       = "AzureMonitorLinuxAgent_${each.value}"
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = "true"
  virtual_machine_id = azurerm_linux_virtual_machine.VM[each.key].id
}
resource "azurerm_monitor_data_collection_rule" "DC_Rule" {
  name                = "DC_Rule_azure_moniter"
  resource_group_name = azurerm_resource_group.RG1.name
  location            = azurerm_resource_group.RG1.location
  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.Log_Workspace.id
      name                  = "destination-log"
    }
    azure_monitor_metrics {
      name = "metrics"
    }
  } 

  data_flow {
    streams      = ["Microsoft-Syslog"]
    destinations = ["destination-log"]
  }

  data_sources {
    syslog {
      facility_names = ["daemon", "syslog"]
      log_levels     = ["Warning", "Error", "Critical", "Alert", "Emergency"]
      name           = "datasource-syslog"
    }
    performance_counter {
      streams                       = ["Microsoft-InsightsMetrics"]
      sampling_frequency_in_seconds = 60
      counter_specifiers            = ["\\VmInsights\\DetailedMetrics"]
      name                          = "VMInsightsPerfCounters"
    }
  }
}
# associate to a Data Collection Rule
resource "azurerm_monitor_data_collection_rule_association" "DC_Rule_Association" {
  for_each                = toset(var.VMcount) 
  name                    = "DRA_${each.value}"
  target_resource_id      = azurerm_linux_virtual_machine.VM[each.key].id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.DC_Rule.id
}