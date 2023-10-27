terraform {
  required_version = ">= 0.12"
}

provider "azurerm" {
  #version = "~>3.0" //outbound_type https://github.com/terraform-providers/terraform-provider-azurerm/blob/v2.5.0/CHANGELOG.md
  skip_provider_registration = true
  features {}
}

data "azuread_client_config" "current" { 
}

resource "azurerm_resource_group" "aks" {
  name     = "${var.prefix}-AKS-RG"
  location = var.location
}

module "aks_network" {
  source              = "./modules/vnet"
  resource_group_name = azurerm_resource_group.aks.name
  location            = var.location
  vnet_name           = "${var.prefix}-AKS-VNET"
  address_space       = ["10.30.0.0/16"]
  subnets = [
    {
      name : "AKS-SUBNET"
      address_prefixes : ["10.30.1.0/24"]
    },
    {
      name : "AKS-AppGw-SUBNET"
      address_prefixes : ["10.30.0.0/24"]
    }
  ]
}

# refer to my team ad group to assign as aks admins 
resource "azuread_group" "myteam" {
  display_name     = "AKS_owners"
  owners = [data.azuread_client_config.current.object_id]
  security_enabled = true
}
#pip for appgw
module "pip" {
  source = "./modules/PublicIP"
  pip_name = "${var.prefix}-AKS-AppGw-PIP"
  location = var.location
  resource_group_name = azurerm_resource_group.aks.name
}

#KV to store certs and secrets,here we are storing cert
module "kv" {      
  source = "./modules/keyvault"
  kv_name = "${var.prefix}-AKS-KV"
  kv_rg_location = var.location
  kv_rg_name = azurerm_resource_group.aks.name
  kv_cert_name = var.cert_name
  cert_name = var.cert_name # we have to mention cert name located in modules/appgw/certs
  kv_cert_pwd = var.cert_pwd
  certificate_name = var.cert_name
  kv_public_nw_access_enabled = true
}
#creating user managed identity to assign key vault access policy
resource "azurerm_user_assigned_identity" "agw" {
  location            = var.location
  resource_group_name = azurerm_resource_group.aks.name
  name                = "${var.prefix}-AKS-APPGW-UMID"
}

#appgw resource
module "appgw" {
  depends_on = [ module.kv,
                 module.aks_network,
                 module.pip
  ]
  source = "./modules/appgw"
  appgw_identity_ids = azurerm_user_assigned_identity.agw.id
  application_gateway_name = "${var.prefix}-AKS-APPGW"
  application_gateway_rg = azurerm_resource_group.aks.name
  frontend_ip_configuration_name = "${var.prefix}-AKS-APPGW-FRONTENDCONFIG"
  frontend_ip_configuration_pip = module.pip.aks_pip
  frontend_ip_configuration_private_ip = "10.30.0.100"
  frontend_ip_configuration_private_name = "${var.prefix}-AKS-APPGW-RIVATE-FRONTENDCONFIG"
  frontend_ip_configuration_private_subnet = module.aks_network.subnet_ids["AKS-AppGw-SUBNET"]
  http_listener_frontend_ip_config_name = "${var.prefix}-AKS-APPGW-HTTP-LISTENER-FRONTENDCONFIG"
  https_listener_frontend_ip_config_name = "${var.prefix}-AKS-APPGW-HTTPS-LISTENER-FRONTENDCONFIG"
  location = var.location
  gateway_ip_configuration_subnet = module.aks_network.subnet_ids["AKS-AppGw-SUBNET"]
  appgw_kv_cert_secret_id = module.kv.keyvault_uploaded_cert_secret_id
  cert_name = var.cert_name
}


# Create keyvault access policies for resources here appgw to GET
resource "azurerm_key_vault_access_policy" "appgw_kv_access" {
  depends_on              = [module.kv,
                             azurerm_user_assigned_identity.agw]
  key_vault_id            = module.kv.keyvault_id
  tenant_id               = data.azuread_client_config.current.tenant_id
  object_id               = azurerm_user_assigned_identity.agw.principal_id
  key_permissions         = ["Get"]
  secret_permissions      = ["Get"]
  certificate_permissions = ["Get"]
}

data "azurerm_kubernetes_service_versions" "current" {
  location       = var.location
  version_prefix = var.kube_version_prefix
}

resource "azurerm_kubernetes_cluster" "aks" {
  depends_on = [ module.appgw]      
  name                    = "${var.prefix}-AKS"
  location                = var.location
  kubernetes_version      = data.azurerm_kubernetes_service_versions.current.version_prefix
  resource_group_name     = azurerm_resource_group.aks.name
  dns_prefix              = "${var.prefix}-aks"

#for private cluster,we have to deploy jumpbox in same vnet
# private_cluster_enabled = true

  network_profile {
    network_plugin = "azure"
  }
  default_node_pool {
    name           = "default"
    node_count     = var.nodepool_nodes_count
    enable_auto_scaling = true
    min_count = 1
    max_count = 10
    max_pods = 50
    vm_size        = var.nodepool_vm_size
    vnet_subnet_id = module.aks_network.subnet_ids["AKS-SUBNET"]
    temporary_name_for_rotation = lower("${var.prefix}tempnode")
  }

  windows_profile {
    admin_username = "sagar"
    admin_password = "Sagar@123456789"
  }

  identity {
    type = "SystemAssigned"
  }

  ingress_application_gateway {
    gateway_id = module.appgw.appgw_id
  }

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled = false
    managed            = true
    # add my team as cluster admin 
    admin_group_object_ids = [azuread_group.myteam.object_id] # azure AD group object ID
  }
}

# resource "azurerm_kubernetes_cluster_node_pool" "aks_nodepool_win" {

#   lifecycle {
#     ignore_changes = [node_count]
#   }

#   name                  = lower("${var.prefix}pool")
#   orchestrator_version  = data.azurerm_kubernetes_service_versions.current.version_prefix
#   kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
#   enable_auto_scaling   = true
#   node_count            = 1
#   min_count             = 1
#   max_count             = 20
#   max_pods              = 30
#   vm_size               = "Standard_B4ms"
#   os_type               = "Windows"
#   vnet_subnet_id        = module.aks_network.subnet_ids["AKS-SUBNET"]
#   os_disk_size_gb       = "512"
#   scale_down_mode       = "Delete"

#   depends_on = [
#     azurerm_kubernetes_cluster.aks
#   ]

# }

resource "azurerm_role_assignment" "netcontributor-aks-subnet" {
  depends_on = [ module.aks_network ]
  role_definition_name = "Network Contributor"
  scope                = module.aks_network.subnet_ids["AKS-SUBNET"]
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}

resource "azurerm_role_assignment" "netcontributor-aks-appgw-subnet" {
  depends_on = [ module.aks_network ]
  role_definition_name = "Network Contributor"
  scope                = module.aks_network.subnet_ids["AKS-AppGw-SUBNET"]
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}


#ACR Resource 
module "acr" {
  source = "./modules/acr"
  acr_name = "${var.prefix}AKSACR"
  location = var.location
  acr_rg = azurerm_resource_group.aks.name
}

#attaching ACR to AKS
resource "azurerm_role_assignment" "acr_attach" {
  principal_id                     = azurerm_kubernetes_cluster.aks.identity[0].principal_id
  role_definition_name             = "AcrPull"
  scope                            = module.acr.acr_id
  skip_service_principal_aad_check = true
}

# Ingess agw for aks is not getting the managed identity assigned automatically when attached with TF
# need to get the user assigned managed id from node rg when it is available after cluster creation

# get node rg
data "azurerm_resource_group" "aks_mc_node_rg" {
  name = azurerm_kubernetes_cluster.aks.node_resource_group
  depends_on = [
    azurerm_kubernetes_cluster.aks
  ]
}

# get user assigned manged id for inress appgw
data "azurerm_user_assigned_identity" "aks_agw_uid" {
  resource_group_name = data.azurerm_resource_group.aks_mc_node_rg.name
  name                = "ingressapplicationgateway-${azurerm_kubernetes_cluster.aks.name}"

  depends_on = [
    azurerm_kubernetes_cluster.aks,
  ]
}

# assign user assigned ingress managed id of aks to appgw - required to allow AGIC to manage agw
resource "azurerm_role_assignment" "aks_agw_role" {
  principal_id         = data.azurerm_user_assigned_identity.aks_agw_uid.principal_id
  role_definition_name = "Contributor"
  scope                = module.appgw.appgw_id

  depends_on = [
    azurerm_kubernetes_cluster.aks,
    azurerm_resource_group.aks,
    data.azurerm_user_assigned_identity.aks_agw_uid
  ]
}

# assign user assigned ingress managed id of aks to ingress agw subnet 
resource "azurerm_role_assignment" "aks_agw_snet_role" {
  principal_id         = data.azurerm_user_assigned_identity.aks_agw_uid.principal_id
  role_definition_name = "Network Contributor"
  scope                = module.aks_network.subnet_ids["AKS-AppGw-SUBNET"]

  depends_on = [
    azurerm_kubernetes_cluster.aks,
    data.azurerm_resource_group.aks_mc_node_rg,
    data.azurerm_user_assigned_identity.aks_agw_uid
  ]
}

# assign user assigned aks-ingressappgw UMID to appgw UMID - required to allow AGIC to manage agw
resource "azurerm_role_assignment" "agw_role" {
  principal_id         = data.azurerm_user_assigned_identity.aks_agw_uid.principal_id
  role_definition_name = "Managed Identity Operator"
  scope                = azurerm_user_assigned_identity.agw.id
}