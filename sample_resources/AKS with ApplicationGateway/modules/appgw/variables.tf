variable "application_gateway_name" {
  type = string
}
variable "application_gateway_rg" {
    type = string
}
variable "location" {
    type = string
}
variable "gateway_ip_configuration_subnet" {
    type = string
}
variable "frontend_ip_configuration_name" {
    type = string  
}
variable "frontend_ip_configuration_pip" {
    type = string
}
variable "frontend_ip_configuration_private_ip" {
  type = string
}
variable "frontend_ip_configuration_private_name" {
  type = string
}
variable "frontend_ip_configuration_private_subnet" {
  type = string
}