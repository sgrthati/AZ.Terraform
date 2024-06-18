data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}
locals {
  resource_group_name = "${data.azurerm_resource_group.main.name}"
  location            = "${var.location != "" ? var.location : data.azurerm_resource_group.main.location}"
  pip_name = "${var.pip_name != "" ? var.pip_name : "${var.resource_group_name}-lb-pip"}"
  lb_name = "${var.lb_name != "" ? var.lb_name : "${var.resource_group_name}-lb"}"
  be_pool_name = "${var.lb_name != "" ? var.lb_name : "${var.resource_group_name}-be-pool"}"
  tags = "${merge(
    data.azurerm_resource_group.main.tags,
    var.tags
  )}"
}

#public ip for azure loadbalancer
resource "azurerm_public_ip" "lb_public_ip" {
  count = var.lb_enabled == true ? 1 : 0
  name                = "${local.pip_name}"
  resource_group_name = local.resource_group_name
  location            = local.location
  sku = "Standard"
  allocation_method   = "Static"
}

#the loadbalancer
resource "azurerm_lb" "lb" {
  count = var.lb_enabled == true ? 1 : 0
  name                = "${local.lb_name}"
  resource_group_name = local.resource_group_name
  location            = local.location
  sku                 = "Standard"
  frontend_ip_configuration {
    name                 = "lb_publicIPAddress"
    public_ip_address_id = var.lb_enabled == true ? "${azurerm_public_ip.lb_public_ip[0].id}" : null
  }
}
resource "azurerm_lb_backend_address_pool" "backend-pool" {
  count = var.lb_enabled == true ? 1 : 0
  name = "${local.be_pool_name}"
  loadbalancer_id = azurerm_lb.lb[0].id
}
