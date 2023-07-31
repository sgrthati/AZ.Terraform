resource "azurerm_log_analytics_workspace" "Log_Workspace" {
  name                      = "vmloganalytics"
  resource_group_name       = azurerm_resource_group.RG1.name
  location                  = azurerm_resource_group.RG1.location
  sku                       = "PerGB2018"
  retention_in_days         = 60
  internet_ingestion_enabled= true
  internet_query_enabled    = false
}
resource "azurerm_log_analytics_linked_storage_account" "LAW_Storage" {
  data_source_type      = "CustomLogs"
  resource_group_name   = azurerm_resource_group.RG1.name
  workspace_resource_id = azurerm_log_analytics_workspace.Log_Workspace.id
  storage_account_ids   = [azurerm_storage_account.Storage_account.id]
}