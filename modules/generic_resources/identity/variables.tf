variable "resource_group_name" {
  description = "The name of an existing resource group for the Managed Identity"
  default = "sri"
}

variable "mgi_id_name" {
    description = "Managed identity name" 
    default = ""  
}
variable "role_def_name" {
  description = "role defination name"
  default = ""
  
}
variable "Environment" {
    description = "Environment"
    type = string
    default = "test"
}
variable "location" {
  description = "The Azure region of the Managed Identity"
  default = "Central India"
}

variable "sys_id_enabled" {
  description = "if it is true,it won't create user_managed_idetity"
  default = "false"
  
}


variable "tags" {
  type        = map
  description = "(Optional) A map of the tags to use on the resources that are deployed with this module. Tags will be merged with those defined by the resource group."

  default = {
    source = "Terraform"
  }
}