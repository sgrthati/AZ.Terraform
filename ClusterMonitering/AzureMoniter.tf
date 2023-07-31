#Azure moniter agent for linux
resource "azurerm_virtual_machine_extension" "AzureMonitorLinuxAgent" {
  for_each                   = toset(var.VMcount)
  name                       = "AzureMonitorLinuxAgent_${each.value}"
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = "true"
  virtual_machine_id = azurerm_linux_virtual_machine.VM[each.key].id
}
resource "azurerm_monitor_data_collection_rule" "DC_Rule" {
  name                = "DC_Rule_azure_moniter"
  resource_group_name = azurerm_resource_group.RG1.name
  location            = azurerm_resource_group.RG1.location
  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.Log_Workspace.id
      name                  = "destination-log"
    }
    azure_monitor_metrics {
      name = "metrics"
    }
  } 

  data_flow {
    streams      = ["Microsoft-Syslog"]
    destinations = ["destination-log"]
  }

  data_sources {
    syslog {
      facility_names = ["daemon", "syslog"]
      log_levels     = ["Warning", "Error", "Critical", "Alert", "Emergency"]
      name           = "datasource-syslog"
    }
    performance_counter {
      streams                       = ["Microsoft-InsightsMetrics"]
      sampling_frequency_in_seconds = 60
      counter_specifiers            = ["\\VmInsights\\DetailedMetrics"]
      name                          = "VMInsightsPerfCounters"
    }
  }
}
# associate to a Data Collection Rule
resource "azurerm_monitor_data_collection_rule_association" "DC_Rule_Association" {
  for_each                = toset(var.VMcount) 
  name                    = "DRA_${each.value}"
  target_resource_id      = azurerm_linux_virtual_machine.VM[each.key].id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.DC_Rule.id
}
resource "azurerm_monitor_action_group" "AG_group" {
  name                = "AG_group"
  resource_group_name = azurerm_resource_group.RG1.name
  short_name          = "P0-Action"

  email_receiver {
    name          = "Admin"
    email_address = var.email
  }

#   email_receiver {
#     name          = "sendtodevops"
#     email_address = "devops@contoso.com"
#   }

#   sms_receiver {
#     name         = "oncallmsg"
#     country_code = "1"
#     phone_number = "1231231234"
#   }

#   webhook_receiver {
#     name        = "callmyapiaswell"
#     service_uri = "http://example.com/alert"
#   }
}
resource "azurerm_monitor_metric_alert" "alerts" {
  for_each            = toset(var.VMcount)
  name                = "CPU_Alert-SRIVM-${each.value}"
  resource_group_name = azurerm_resource_group.RG1.name
  scopes              = [azurerm_linux_virtual_machine.VM[each.key].id]
  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }
  action {
    action_group_id = azurerm_monitor_action_group.AG_group.id
  }
}
#Enable Azure Diagnostics setting
resource "azurerm_virtual_machine_extension" "diagnosics" {
  for_each                   = toset(var.VMcount)
  name                       = "DiagSetting_srivm_${each.value}"
  virtual_machine_id         = azurerm_linux_virtual_machine.VM[each.key].id
  publisher                  = "Microsoft.Azure.Diagnostics"
  type                       = "LinuxDiagnostic"
  type_handler_version       = "3.0"
  auto_upgrade_minor_version = true
   depends_on = [
      azurerm_storage_account.Storage_account
  ]
   settings = <<SETTINGS
    {
      "StorageAccount": "${azurerm_storage_account.Storage_account.name}",
      "ladCfg": {
          "diagnosticMonitorConfiguration": {
                "eventVolume": "Medium", 
                "metrics": {
                     "metricAggregation": [
                        {
                            "scheduledTransferPeriod": "PT1H"
                        }, 
                        {
                            "scheduledTransferPeriod": "PT1M"
                        }
                    ], 
                    "resourceId": "${azurerm_linux_virtual_machine.VM[each.key].id}"
                },
                "performanceCounters": ${file("/configs/performancecounters.json")},
                "syslogEvents": ${file("/configs/syslogevents.json")}
          }, 
          "sampleRateInSeconds": 15
      }
    }
  SETTINGS

  protected_settings = <<SETTINGS
    {
        "storageAccountName": "${azurerm_storage_account.Storage_account.name}",
        "storageAccountSasToken": "${data.azurerm_storage_account_sas.sas_token.sas}",
         "sinksConfig":  {
              "sink": [
                {
                    "name": "SyslogJsonBlob",
                    "type": "JsonBlob"
                },
                {
                    "name": "LinuxCpuJsonBlob",
                    "type": "JsonBlob"
                }
              ]
        }
    }
SETTINGS
}