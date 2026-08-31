resource "azurerm_log_analytics_workspace" "log_analytics" {
  name                = "law-cloudsec-lab-dev"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_monitor_diagnostic_setting" "appgw_diagnostics" {
  name               = "diag-appgw-waf"
  target_resource_id = azurerm_application_gateway.appgw.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics.id

  enabled_log {
    category = "ApplicationGatewayAccessLog"
  }

    enabled_log {
        category = "ApplicationGatewayFirewallLog"
    }
}