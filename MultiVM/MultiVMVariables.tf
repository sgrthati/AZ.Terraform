variable "resource_groups" {
  description = "(Required) A list of Azure Resource Groups with locations and tags"
  default = "SRI"
}
variable "location" {
  default = "Central India"
}
variable "NSG" {
  default = "SRI-NSG"
}
variable "VNET" {
  default = "SRI-VNET"
}
variable "subnet" {
  default = "SRI-SUBNET"
}
variable "publicIP" {
  default = "SRI-PIP"
}
variable "NIC" {
  default = "SRI-NIC"
}
variable "VM" {
  default = "SRIVM"
}
variable "VMcount" {
  default = 2
}