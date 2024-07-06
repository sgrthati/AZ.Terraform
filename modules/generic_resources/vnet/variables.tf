variable "VNET_name" {
    default = ""
}

variable "subnet_name" {
    default = ""
}

variable "RG_name" {
    default = ""
}

variable "nsg_name" {
    default = ""
}
variable "resource_group_name" {
    default = ""
}
variable "location" {
    default = ""
}
variable "allowed_inbound_ports" {
  description = "Map of allowed inbound ports with priorities"
  type = map(object({
    port     = string
    priority = number
  }))
  default = {
    "AllowSSH" = {
      port     = "22"
      priority = 100
    }
    "AllowHTTP" = {
      port     = "80"
      priority = 110
    }
    "AllowHTTPS" = {
      port     = "443"
      priority = 120
    }
  }
}