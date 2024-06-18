variable "resource_group_name" { 
}
variable "dns_name" {
  description = "DNS name"
}
variable "dns_vnet_id" {
}
variable "dns_enabled" {
  default = false
}

variable "tags" {
  type        = map
  description = "(Optional) A map of the tags to use on the resources that are deployed with this module. Tags will be merged with those defined by the resource group."

  default = {
    source = "Terraform"
    Environment = "Test"
  }
}