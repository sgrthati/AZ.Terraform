variable "kv_rg_name" {
    description = "Resource Group Name"
    type = string
}
variable "kv_rg_location" {
    description = "Resource Group Location"
    type = string
}
variable "kv_name" {
    description = "Azure Key Vault Name"
    type = string
}
variable "kv_enabled_for_deployment" {
    description = "Azure Key Vault Enabled for Deployment"
    type = string
    default = "true"
}
variable "kv_enabled_for_disk_encryption" {
    description = "Azure Key Vault Enabled for Disk Encryption"
    type = string
    default = "true"
}
variable "kv_enabled_for_template_deployment" {
    description = "Azure Key Vault Enabled for Deployment"
    type = string
    default = "true"
}
variable "kv_sku_name" {
    description = "Azure Key Vault SKU (Standard or Premium)"
    type = string
    default = "standard"
}
variable "kv_cert_name" {
    type = string
}
variable "cert_name" {
    type = string 
}
variable "kv_cert_pwd" {
    type = string
}
variable "certificate_name" {
}
variable "kv_public_nw_access_enabled" {
    type = string
}
