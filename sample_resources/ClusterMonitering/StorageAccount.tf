resource "random_string" "string" {
    length = 8
    lower = true
    upper = false
    numeric = false
    special = false
}
resource "azurerm_storage_account" "Storage_account" {
  name                     = "srisri${random_string.string.result}"
  resource_group_name      = azurerm_resource_group.RG1.name
  location                 = azurerm_resource_group.RG1.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
//== Store 10 years in the future ==//
resource "time_offset" "sas_expiry" {
  offset_years = "30"
}
resource "time_offset" "sas_start" {
  offset_days = "-10"
}
#to retrive sas token,to pass it azure diagnostic settings
data "azurerm_storage_account_sas" "sas_token" {
  depends_on = [ azurerm_storage_account.Storage_account ]
  connection_string = azurerm_storage_account.Storage_account.primary_connection_string
  https_only        = true
  signed_version    = "2017-07-29"

  resource_types {
    service   = true
    container = false
    object    = false
  }

  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }

  start  = time_offset.sas_start.rfc3339
  expiry = time_offset.sas_expiry.rfc3339

  permissions {
    read    = true
    write   = true
    delete  = false
    list    = false
    add     = true
    create  = true
    update  = false
    process = false
    tag     = false
    filter  = false
  }
}