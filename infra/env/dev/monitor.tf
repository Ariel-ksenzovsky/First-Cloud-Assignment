# ===========================
# Action Group for alerts
# ===========================
resource "azurerm_monitor_action_group" "dev_alerts" {
  name                = "${local.project_name}-ag"
  resource_group_name = azurerm_resource_group.app.name
  short_name          = "devag"

  email_receiver {
    name          = "dev-admin"
    email_address = "arielk@sela.com"
  }
}

# ==========================================
# Memory monitor - Data Collection Rule
# ==========================================
# resource "azurerm_monitor_data_collection_rule" "vm_dcr" {
#   name                = "${local.project_name}-dcr"
#   resource_group_name = azurerm_resource_group.app.name
#   location            = local.location

#   data_flow {
#     streams      = ["Microsoft-InsightsMetrics"]
#     destinations = ["metrics"]
#   }

#   data_sources {
#     performance_counter {
#       name                = "perfCounters"
#       streams             = ["Microsoft-InsightsMetrics"]
#       counter_specifiers  = [
#         "\\Memory\\Available MBytes",
#         "\\Memory\\% Committed Bytes In Use"
#       ]
#       sampling_frequency_in_seconds = 15
#     }
#   }

#   destinations {
#     azure_monitor_metrics {
#       name = "metrics"
#     }
#     }
#   }

# # ==========================================
# # Data Collection Rule Association
# # ==========================================
# resource "azurerm_monitor_data_collection_rule_association" "vm_dca" {
#   name                    = "${local.project_name}-dca"
#   target_resource_id      = azurerm_linux_virtual_machine.web.id
#   data_collection_rule_id = azurerm_monitor_data_collection_rule.vm_dcr.id
# }

# ==========================================
# CPU alert: Average CPU > 80% for 5 minutes
# ==========================================
resource "azurerm_monitor_metric_alert" "web_cpu_high" {
  name                = "${local.project_name}-web-cpu-high"
  resource_group_name = azurerm_resource_group.app.name
  scopes              = [azurerm_linux_virtual_machine.web.id]

  description = "CPU usage on dev-cloud-web-vm is high"
  severity    = 3                      # 0 (critical) .. 4 (info)
  enabled     = true

  frequency   = "PT1M"                 # check every 1 minute
  window_size = "PT5M"                 # look at last 5 minutes

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.dev_alerts.id
  }
}

# =========================================================
# Memory alert – Average Memory > 80% for 5 minutes
# =========================================================
# resource "azurerm_monitor_metric_alert" "vm_memory" {
#   name                = "vm-memory-alert"
#   resource_group_name = azurerm_resource_group.app.name
#   scopes              = [azurerm_linux_virtual_machine.web.id]

#   description = "Memory usage is above 80%"
#   severity    = 2
#   enabled     = true

#   window_size = "PT5M"
#   frequency   = "PT1M"

#   criteria {
#     metric_namespace = "InsightsMetrics"
#     metric_name      = "Memory\\Committed Bytes In Use"
#     aggregation      = "Average"
#     operator         = "GreaterThan"
#     threshold        = 80
#   }

#   action {
#     action_group_id = azurerm_monitor_action_group.dev_alerts.id
#   }
# }
