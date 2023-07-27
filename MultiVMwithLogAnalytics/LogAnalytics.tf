resource "azurerm_log_analytics_workspace" "Log_Workspace" {
  name                      = "vmloganalytics"
  resource_group_name       = azurerm_resource_group.RG1.name
  location                  = azurerm_resource_group.RG1.location
  sku                       = "PerGB2018"
  retention_in_days         = 365
  internet_ingestion_enabled= true
  internet_query_enabled    = false
}

resource "azurerm_log_analytics_solution" "vminsights" {
  solution_name         = "vminsights"
  resource_group_name   = azurerm_resource_group.RG1.name
  location              = azurerm_resource_group.RG1.location
  workspace_resource_id = azurerm_log_analytics_workspace.Log_Workspace.id
  workspace_name        = azurerm_log_analytics_workspace.Log_Workspace.name
  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/VMInsights"
  }
}