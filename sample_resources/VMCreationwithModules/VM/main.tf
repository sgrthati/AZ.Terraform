resource "azurerm_windows_virtual_machine" "VM1" {
  name                = var.VM_name
  resource_group_name = var.RG_name
  location            = var.location
  size                = "Standard_B1s"
  admin_username      = "SAGAR.THATI"
  admin_password      = "AZURE@123456"
  network_interface_ids = var.NIC

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