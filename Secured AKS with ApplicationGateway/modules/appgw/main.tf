resource "azurerm_application_gateway" "aks_appgw" {
  name                = var.application_gateway_name
  location            = var.location
  resource_group_name = var.application_gateway_rg

  sku {
    name = "Standard_v2"
    tier = "Standard_v2"
  }

  autoscale_configuration {
    min_capacity = 1
    max_capacity = 10
  }

  ssl_certificate {
    name     = var.cert_name
    key_vault_secret_id = var.appgw_kv_cert_secret_id
  }

  gateway_ip_configuration {
    name      = "agwIpConfig"
    subnet_id = var.gateway_ip_configuration_subnet

  }

  frontend_port {
    name = "port80"
    port = 80
  }

  # need to have a public IP for Standard_v2 AGW. will not be used with any listerners by AKS
  frontend_ip_configuration {
    name                 = var.frontend_ip_configuration_name
    public_ip_address_id = var.frontend_ip_configuration_pip
  }

  frontend_ip_configuration {
    name                          = var.http_listener_frontend_ip_config_name
    private_ip_address            = var.frontend_ip_configuration_private_ip
    private_ip_address_allocation = "Static"
    subnet_id                     = var.frontend_ip_configuration_private_subnet
  }

  # dummy intial configuration for backend, listners, rules
  # in agw is required to set it up
  backend_address_pool {
    name = "Backend"
  }

  backend_http_settings {
    name                  = "BackendSettings"
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }
   # HTTPS Listener - Port 80
  http_listener {
    name                           = "Listener"
    frontend_ip_configuration_name =  var.http_listener_frontend_ip_config_name
    frontend_port_name             = "port80"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "dummyRule"
    rule_type                  = "Basic"
    http_listener_name         = "Listener"
    backend_address_pool_name  = "Backend"
    backend_http_settings_name = "BackendSettings"
    priority                   = 100
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [var.appgw_identity_ids]
  }

  # after we hand over the control to aks cluster to
  # manage configurations for aks ingress in the agw
  # we have to prevent update via terraform to below configurations in agw
  # tags is not madatory to ignore but nice to have
  lifecycle {
    ignore_changes = [
      backend_address_pool,
      backend_http_settings,
      http_listener,
      probe,
      request_routing_rule,
      url_path_map,
      rewrite_rule_set,
      frontend_port,
      tags
    ]
  }
}