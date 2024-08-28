variable "location" {
  description = "The location where the resources will be created."
  default = "Central India"
}
variable "aks_cluster_name" {
  type        = string
  description = "Name of your AKS cluster"
  default = ""
}
variable "user_principal_name" {
  type = string
  description = "user principal name"
}
variable "service_principal_name" {
  type = string
  description = "Service principal name"
  default = ""
}
variable "tags" {
  type        = map
  description = "(Optional) A map of the tags to use on the resources that are deployed with this module. Tags will be merged with those defined by the resource group."

  default = {
    source = "Terraform"
  }
}
variable "resource_group_name" {
  type        = string
  description = "Resource group name that the AKS cluster is located in"
}
variable "ssh_public_key" {
  description = "value"
  default = "./.ssh/id_rsa.pub"
}

variable "add_pool" {
  description = "if true,it will create additional pool"
  default = ""
}
# variable "client_id" {
#   type=string
#   description="Azure Service Principal client id"
# }
# variable "client_secret" {
#   type      = string
#   description = "value for Azure Service Principal password"
#   sensitive = true
# }
