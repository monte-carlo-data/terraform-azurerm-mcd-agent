output "mcd_agent_function_url" {
  value       = "https://${var.remote_upgradable ? azurerm_linux_function_app.mcd_agent_service_with_remote_upgrade_support[0].default_hostname : azurerm_linux_function_app.mcd_agent_service[0].default_hostname}"
  description = "The URL for the agent."
}

output "mcd_agent_function_name" {
  value       = var.remote_upgradable ? azurerm_linux_function_app.mcd_agent_service_with_remote_upgrade_support[0].name : azurerm_linux_function_app.mcd_agent_service[0].name
  description = "Agent function name."
}

output "mcd_agent_resource_group_name" {
  value       = local.mcd_agent_resource_group_name
  description = "Agent service resource group."
}

output "mcd_agent_service_identity_principal_id" {
  value       = azurerm_user_assigned_identity.mcd_agent_service_identity.principal_id
  description = "Agent service principal id."
}

output "mcd_agent_auth_type" {
  value       = var.auth_type
  description = "The auth type configured for this agent deployment."
}

output "mcd_agent_sp_tenant_id" {
  value       = local.use_sp_auth ? data.azuread_client_config.current.tenant_id : null
  description = "Entra ID tenant ID for service principal auth. Null if using app key auth."
}

output "mcd_agent_sp_client_id" {
  value       = local.use_sp_auth ? azuread_application.mcd_agent_caller[0].client_id : null
  description = "Caller service principal client ID. Null if using app key auth."
}

output "mcd_agent_sp_client_secret" {
  value       = local.use_sp_auth ? azuread_application_password.mcd_agent_caller_secret[0].value : null
  description = "Caller service principal client secret. Null if using app key auth."
  sensitive   = true
}

output "mcd_agent_sp_audience" {
  value       = local.use_sp_auth ? one(azuread_application.mcd_agent_function_app[0].identifier_uris) : null
  description = "Function App audience URI for service principal auth. Null if using app key auth."
}