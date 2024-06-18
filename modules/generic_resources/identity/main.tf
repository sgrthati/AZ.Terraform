#azure client details
data "azurerm_client_config" "current" {}
#azuure subscription
data "azurerm_subscription" "current" {}
#data module for resource group
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

#locals defined
locals {
  name                = join("-",["${data.azurerm_resource_group.main.name}","${var.Environment}"])
  resource_group_name = "${data.azurerm_resource_group.main.name}"
  location            = "${var.location != "" ? var.location : data.azurerm_resource_group.main.location}"
  mgi_id_name         = "${var.mgi_id_name != "" ? var.mgi_id_name : "${local.name}-msi"}"
  role_def_name       = "${var.role_def_name != "" ? var.role_def_name : "${local.name}-role_def"}"

  tags = "${merge(
    data.azurerm_resource_group.main.tags,
    var.tags
  )}"
}

resource "azurerm_user_assigned_identity" "mgd_id" {
  count               = var.sys_id_enabled == false ? 1 : 0 
  name                =  local.mgi_id_name
  location            = "${local.location}"
  resource_group_name = "${local.resource_group_name}"
  tags                = "${local.tags}"
}

# resource "azurerm_role_definition" "role_def" {
#   count       = var.sys_id_enabled == false ? 1 : 0 
#   name        = local.role_def_name
#   scope       = data.azurerm_subscription.current.id
#   description = "This is a custom role created via Terraform for Managed Identity ${local.mgi_id_name}"

#   permissions {
#     actions     = ["*"]
#     not_actions = []
#   }
#   assignable_scopes = [
#     data.azurerm_subscription.current.id
#   ]
# }

resource "azurerm_role_assignment" "role_asn" {
  count              = var.sys_id_enabled == false ? 1 : 0 
  scope              = "${data.azurerm_subscription.current.id}"
  role_definition_name = "Contributor"
  # role_definition_id =  "/subscriptions/${data.azurerm_subscription.current.id}/providers/Microsoft.Authorization/roleDefinitions/${azurerm_role_definition.role_def[0].id}"
  principal_id       = azurerm_user_assigned_identity.mgd_id[0].principal_id
}