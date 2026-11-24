variable "acr_name" {
  description = "Name of an existing Azure Container Registry holding the agent image."
  type        = string
}

variable "acr_resource_group_name" {
  description = "Resource group of the Azure Container Registry."
  type        = string
}

variable "image" {
  description = "Agent image repository and tag inside the registry, e.g. mcd-agent/agent:<version>-azure."
  type        = string
}

provider "azurerm" {
  features {}
}

data "azurerm_container_registry" "agent" {
  name                = var.acr_name
  resource_group_name = var.acr_resource_group_name
}

module "apollo" {
  source = "../../"

  image                               = var.image
  image_registry                      = data.azurerm_container_registry.agent.login_server
  image_registry_use_managed_identity = true
  image_registry_acr_id               = data.azurerm_container_registry.agent.id

  # Monte Carlo-initiated upgrades use Docker Hub images, which an agent running from a private
  # registry rejects. Upgrade by changing `image` and applying instead.
  remote_upgradable = false
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
