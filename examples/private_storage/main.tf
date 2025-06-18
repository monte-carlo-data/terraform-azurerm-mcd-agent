resource "random_id" "unique_id" {
  byte_length = 4
}

# get the current IP address, used to allow access to the storage account from TF
# to create the share
data "http" "ip" {
  url = "https://checkip.amazonaws.com"
}

locals {
  my_ip = chomp(data.http.ip.response_body)
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
    durable_function_storage_account_name = azurerm_storage_account.durable_function_storage.name
    agent_data_storage_account_name       = azurerm_storage_account.mcd_agent_storage.name
    agent_data_storage_container_name     = azurerm_storage_container.mcd_agent_storage_container.name
  }
  durable_function_storage_account_access_key = azurerm_storage_account.durable_function_storage.primary_access_key
  durable_function_storage_account_share_name = azurerm_storage_share.durable_function_storage.name
  storage_accounts_private_access             = true
  subnet_id                                   = azurerm_subnet.agent.id
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
