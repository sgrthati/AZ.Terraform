variable "resource_groups" {
  description = "(Required) A list of Azure Resource Groups with locations and tags"
  default = "SRI_check"
}
variable "location" {
  default = "Central India"
}
variable "NSG" {
  default = "SRI_NSG"
}
variable "VNET" {
  default = "SRI_VNET"
}
variable "subnet" {
  default = "SRI_SUBNET"
}
variable "publicIP" {
  default = "SRI_PIP"
}
variable "NIC" {
  default = "SRI_NIC"
}
variable "VM" {
  default = "SRIVM_NEW"
}
variable "VMcount" {
  type = set(string)
  default = [1,2]
}
variable "email" {
  type = string
  default = "sgrthati@gmail.com"
}