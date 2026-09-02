output "appgw_public_ip" {
  description = "The public IP address of the Application Gateway"
  value       = azurerm_public_ip.appgw_public_ip.ip_address
}

output "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics Workspace"
  value = azurerm_log_analytics_workspace.log_analytics.id
}