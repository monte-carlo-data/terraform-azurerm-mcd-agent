resource "random_id" "unique_id" {
  byte_length = 4
}

locals {
  suffix              = random_id.unique_id.hex
  resource_group_name = "mcd-agent-private-storage"

  durable_function_storage_account_name = "mcdagent0fs${local.suffix}"
  agent_data_storage_account_name       = "mcdagent1fs${local.suffix}"
  agent_data_storage_container_name     = "mcdstore"
  agent_data_store_data_prefix          = "mcd"
}

# Create the resource group
resource "azurerm_resource_group" "mcd_agent_rg" {
  name     = local.resource_group_name
  location = var.location
}

# Deploy the MC Agent
module "apollo" {
  source = "../../"

  existing_resource_group_name = azurerm_resource_group.mcd_agent_rg.name
  existing_storage_accounts = {
    agent_durable_function_storage_account_name       = azurerm_storage_account.durable_function_storage.name
    agent_durable_function_storage_account_access_key = azurerm_storage_account.durable_function_storage.primary_access_key
    agent_durable_function_storage_account_share_name = azapi_resource.durable_function_storage_share.name

    agent_data_storage_account_name   = azurerm_storage_account.mcd_agent_storage.name
    agent_data_storage_container_name = azapi_resource.mcd_agent_storage_container.name

    private_access = true
  }
  subnet_id = azurerm_subnet.agent.id
}

# Grant access to the storage account
resource "azurerm_role_assignment" "mcd_agent_storage_cont_ra" {
  scope                = azurerm_storage_account.mcd_agent_storage.id
  principal_id         = module.apollo.mcd_agent_service_identity_principal_id
  role_definition_name = "Storage Blob Data Contributor"
}

resource "azurerm_role_assignment" "mcd_agent_storage_key_ra" {
  scope                = azurerm_storage_account.mcd_agent_storage.id
  principal_id         = module.apollo.mcd_agent_service_identity_principal_id
  role_definition_name = "Storage Account Key Operator Service Role"
}
