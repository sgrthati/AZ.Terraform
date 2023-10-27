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
variable "http_listener_frontend_ip_config_name" {
  type = string
}
variable "frontend_ip_configuration_private_subnet" {
  type = string
}
variable "cert_name" {
  type = string
}
variable "appgw_kv_cert_secret_id" {
  type = string
}
variable "https_listener_frontend_ip_config_name" {
  type = string
}
variable "frontend_ip_configuration_private_name" {
  type = string
}
variable "appgw_identity_ids" {
  type = string
}