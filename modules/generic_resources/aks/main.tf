data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}
# fetching Azure Active Directory(AD) config
data "azuread_client_config" "current" {}
# Fetching  User details from Resource Manage Subscription
data "azurerm_subscription" "current" {}
# Fetching Azure Resource Manager Client Configuration
data "azurerm_client_config" "current" {}

#locals defined
locals {
  resource_group_name = "${data.azurerm_resource_group.main.name}"
  location            = "${var.location != "" ? var.location : data.azurerm_resource_group.main.location}"
  aks_cluster_name = "${var.aks_cluster_name != "" ? var.aks_cluster_name : "${var.resource_group_name}-aks-cluster"}"
  service_principal_name = "${var.service_principal_name != "" ? var.service_principal_name : "${local.aks_cluster_name}-sp"}"
  tags = "${merge(
    data.azurerm_resource_group.main.tags,
    var.tags
  )}"
}
# Datasource to get Latest Azure AKS latest Version
data "azurerm_kubernetes_service_versions" "current" {
  location = local.location
  include_preview = false  
}
 
resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
# Creating Azure AD Application
resource "azuread_application" "main" {
  display_name = local.service_principal_name
  owners       = [data.azuread_client_config.current.object_id]
}
# Creating AzureAD Service Principle
resource "azuread_service_principal" "main" {
  client_id                    = azuread_application.main.client_id
  app_role_assignment_required = true
  owners                       = [data.azuread_client_config.current.object_id]
  depends_on = [
    data.azurerm_resource_group.main
  ]
}


# Creates and holds Service Principle Id created in previous  step to be used by other resources
resource "azuread_service_principal_password" "main" {
  service_principal_id = azuread_service_principal.main.object_id
  depends_on = [
    azuread_service_principal.main
  ]
}
# Assigning role
resource "azurerm_role_assignment" "rolespn" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.main.object_id
  depends_on = [
    azuread_service_principal.main
  ]
}
data "azuread_user" "self" {
    user_principal_name = var.user_principal_name
}
resource "azuread_group" "k8sadmins" {
  display_name = "Kubernetes Admins"
  members = [
    data.azuread_user.self.object_id,
  ]
  security_enabled = true
}
resource "azurerm_role_assignment" "k8sadmins" {
  depends_on           = [data.azurerm_resource_group.main]
  scope                = data.azurerm_resource_group.main.id
  role_definition_name = "Azure Kubernetes Service Cluster Admin Role"
  principal_id         = azuread_group.k8sadmins.object_id
}

resource "azurerm_kubernetes_cluster" "aks-cluster" {
  name                  = local.aks_cluster_name
  location              = local.location
  resource_group_name   = local.resource_group_name
  dns_prefix            = "${local.resource_group_name}-aks-cluster"         
  kubernetes_version    =  data.azurerm_kubernetes_service_versions.current.latest_version
  node_resource_group = "${local.resource_group_name}-nrg"
  depends_on = [
    azuread_service_principal.main,
    azuread_service_principal_password.main,
    azurerm_role_assignment.rolespn,
    azurerm_role_assignment.k8sadmins,
    data.azuread_user.self,
    azuread_group.k8sadmins
  ]
  azure_active_directory_role_based_access_control {
    azure_rbac_enabled     = true
    admin_group_object_ids = [azuread_group.k8sadmins.id]
  }
  local_account_disabled = true
  
  default_node_pool {
    name       = "defaultpool"
    vm_size    = "Standard_B2s"
    # zones   = [1, 2, 3]
    node_count = 2
    enable_auto_scaling  = true
    max_count            = 2
    min_count            = 1
    os_disk_size_gb      = 30
    type                 = "VirtualMachineScaleSets"
    node_labels = {
      "nodepool-type"    = "system"
      "environment"      = "prod"
      "nodepoolos"       = "linux"
     } 
   tags = {
      "nodepool-type"    = "system"
      "environment"      = "prod"
      "nodepoolos"       = "linux"
   } 
  }
  service_principal  {
    client_id              = "${azuread_application.main.client_id}"
    client_secret          = "${azuread_service_principal_password.main.value}"
  }
  linux_profile {
    admin_username = "ubuntu"
    ssh_key {
        key_data = tls_private_key.pk.public_key_openssh
    }  
  }
  network_profile {
      network_plugin = "azure"
      load_balancer_sku = "standard"
  } 
  }
resource "azurerm_kubernetes_cluster_node_pool" "add_pool" {
  count = "${var.add_pool != "" ? 1 : 0}"
  name                  = "pool${count.index}"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks-cluster.id
  vm_size               = "Standard_B2s"
  node_count            = 1
  os_disk_size_gb       = 250
  os_type               = "Linux"
  node_labels = {
      "nodepool-type"    = "system"
      "environment"      = "prod"
      "nodepoolos"       = "linux"
     } 
  tags = {
      "nodepool-type"    = "system"
      "environment"      = "prod"
      "nodepoolos"       = "linux"
   } 
}

