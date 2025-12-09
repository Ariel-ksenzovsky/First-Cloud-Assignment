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
# Memory alert – DISABLED for now (no metric yet)
# =========================================================
# resource "azurerm_monitor_metric_alert" "web_memory_high" {
#   name                = "${local.project_name}-web-mem-high"
#   resource_group_name = azurerm_resource_group.app.name
#   scopes              = [azurerm_linux_virtual_machine.web.id]
#
#   description = "Memory usage on dev-cloud-web-vm is high"
#   severity    = 3
#   enabled     = true
#
#   frequency   = "PT1M"
#   window_size = "PT5M"
#
#   criteria {
#     metric_namespace = "InsightsMetrics"
#     metric_name      = "Memory\\Committed Bytes In Use"
#     aggregation      = "Average"
#     operator         = "GreaterThan"
#     threshold        = 80
#   }
#
#   action {
#     action_group_id = azurerm_monitor_action_group.dev_alerts.id
#   }
# }
