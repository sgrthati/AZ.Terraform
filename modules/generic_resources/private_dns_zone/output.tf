output "private_dns_zone_name" {
  value = one(azurerm_private_dns_zone.private_dns_zone[*].name)
}