variable "resource_group_name" {
  description = "(Required) The name of the resource group in which the resources will be created"
  default = "sri"
}

variable "tags" {
  type        = map
  description = "(Optional) A map of the tags to use on the resources that are deployed with this module. Tags will be merged with those defined by the resource group."

  default = {
    source = "Terraform"
    Environment = "Test"
  }
}