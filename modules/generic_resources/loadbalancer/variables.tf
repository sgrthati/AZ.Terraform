variable "location" { 
    default = ""
}
variable "pip_name" { 
    default = ""
}
variable "lb_name" { 
    default = ""
}
variable "resource_group_name" {
}
variable "tags" {
  type        = map
  description = "(Optional) A map of the tags to use on the resources that are deployed with this module. Tags will be merged with those defined by the resource group."

  default = {
    source = "Terraform"
    Environment = "Test"
  }
}
variable "lb_enabled" {
  default = false
}