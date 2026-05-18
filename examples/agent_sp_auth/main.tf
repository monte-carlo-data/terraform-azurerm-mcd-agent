module "apollo" {
  source    = "../../"
  auth_type = "AZURE_FUNCTION_SERVICE_PRINCIPAL"
}

output "resource_group" {
  value       = module.apollo.mcd_agent_resource_group_name
  description = "Agent service resource group."
}

output "function_url" {
  value       = module.apollo.mcd_agent_function_url
  description = "The URL for the agent."
}

output "function_name" {
  value       = module.apollo.mcd_agent_function_name
  description = "Agent function name."
}

output "auth_type" {
  value       = module.apollo.mcd_agent_auth_type
  description = "The auth type configured for this agent deployment."
}

# These values are provided to Monte Carlo when registering the agent
output "sp_credentials" {
  value = {
    tenant_id     = module.apollo.mcd_agent_sp_tenant_id
    client_id     = module.apollo.mcd_agent_sp_client_id
    client_secret = module.apollo.mcd_agent_sp_client_secret
    audience      = module.apollo.mcd_agent_sp_audience
  }
  sensitive = true
}
