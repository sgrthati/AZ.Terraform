output "admin_username" {
  value = "${var.admin_username}"
}
output "vm_public_ip" {
  value = [for pip in azurerm_public_ip.pip : pip.ip_address]
}
