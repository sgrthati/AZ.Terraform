data "azurerm_client_config" "current" {
}
data "azuread_client_config" "current" {
}
resource "azurerm_key_vault" "key-vault" {
  name = var.kv_name
  location = var.kv_rg_location
  resource_group_name = var.kv_rg_name
  enabled_for_deployment = var.kv_enabled_for_deployment
  enabled_for_disk_encryption = var.kv_enabled_for_disk_encryption
  enabled_for_template_deployment = var.kv_enabled_for_template_deployment
  tenant_id = data.azuread_client_config.current.tenant_id
  sku_name = var.kv_sku_name
  soft_delete_retention_days = "7"
  purge_protection_enabled   = false
  public_network_access_enabled = var.kv_public_nw_access_enabled
  
  # network_acls {
  #   default_action = "Deny"
  #   bypass         = "AzureServices"
  # }

   access_policy {
    object_id    = data.azurerm_client_config.current.object_id
    tenant_id    = data.azurerm_client_config.current.tenant_id

    certificate_permissions = [
      "Create",
      "Delete",
      "DeleteIssuers",
      "Get",
      "GetIssuers",
      "Import",
      "List",
      "ListIssuers",
      "ManageContacts",
      "ManageIssuers",
      "Purge",
      "SetIssuers",
      "Update"
    ]

    key_permissions = [
      "Backup",
      "Create",
      "Decrypt",
      "Delete",
      "Encrypt",
      "Get",
      "Import",
      "List",
      "Purge",
      "Recover",
      "Restore",
      "Sign",
      "UnwrapKey",
      "Update",
      "Verify",
      "WrapKey"
    ]

    secret_permissions = [
      "Backup",
      "Delete",
      "Get",
      "List",
      "Purge",
      "Restore",
      "Restore",
      "Set"
    ]
  }
}

resource "azurerm_key_vault_certificate" "kv_cert" {
  depends_on              = [azurerm_key_vault.key-vault]
  name         = trim(var.kv_cert_name, ".pfx")
  key_vault_id = azurerm_key_vault.key-vault.id

  certificate {
    contents = filebase64("./modules/appgw/certs/${var.kv_cert_name}")
    password = var.kv_cert_pwd
  }

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = false
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }
  }
}