output "mcd_agent_function_url" {
  value       = "https://${var.remote_upgradable ? azurerm_linux_function_app.mcd_agent_service_with_remote_upgrade_support[0].default_hostname : azurerm_linux_function_app.mcd_agent_service[0].default_hostname}"
  description = "The URL for the agent."
}

output "mcd_agent_function_name" {
  value       = var.remote_upgradable ? azurerm_linux_function_app.mcd_agent_service_with_remote_upgrade_support[0].name : azurerm_linux_function_app.mcd_agent_service[0].name
  description = "Agent function name."
}

output "mcd_agent_resource_group_name" {
  value       = azurerm_resource_group.mcd_agent_rg.name
  description = "Agent service resource group."
}