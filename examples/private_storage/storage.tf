# Storage account use by Azure Durable functions
resource "azurerm_storage_account" "durable_function_storage" {
  name                = local.durable_function_storage_account_name
  resource_group_name = local.resource_group_name
  location            = azurerm_resource_group.mcd_agent_rg.location

  account_tier                      = "Standard"
  account_replication_type          = var.storage_accounts_replication_type
  https_traffic_only_enabled        = true
  allow_nested_items_to_be_public   = false
  infrastructure_encryption_enabled = true

  # Using this approach to allow access from the IP address running Terraform,
  # this is required for the creation of the share below and run TF plan/apply
  # in the future.
  # You can manually disable public access completely after deploying this module,
  # just remember to restore this rule before executing TF again.
  public_network_access_enabled = true
  network_rules {
    default_action = "Deny"
    ip_rules       = [local.my_ip]
  }
}

# Share to use for the Azure Function, for the WEBSITE_CONTENTSHARE setting
resource "azurerm_storage_share" "durable_function_storage" {
  name                 = azurerm_storage_account.durable_function_storage.name
  storage_account_name = azurerm_storage_account.durable_function_storage.name
  quota                = 50
}

# Private endpoints for the Durable function storage account
resource "azurerm_private_endpoint" "durable_function_storage_blob" {
  name                = "mcd_agent_df_blob_endpoint"
  location            = azurerm_resource_group.mcd_agent_rg.location
  resource_group_name = azurerm_resource_group.mcd_agent_rg.name
  subnet_id           = azurerm_subnet.private_endpoint.id

  private_service_connection {
    name                           = "mcd_agent_df_blob"
    private_connection_resource_id = azurerm_storage_account.durable_function_storage.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
  private_dns_zone_group {
    name                 = azurerm_storage_account.durable_function_storage.name
    private_dns_zone_ids = [azurerm_private_dns_zone.dns_storage_blob.id]
  }
}

resource "azurerm_private_endpoint" "durable_function_storage_file" {
  name                = "mcd_agent_df_file_endpoint"
  location            = azurerm_resource_group.mcd_agent_rg.location
  resource_group_name = azurerm_resource_group.mcd_agent_rg.name
  subnet_id           = azurerm_subnet.private_endpoint.id

  private_service_connection {
    name                           = "mcd_agent_df_file"
    private_connection_resource_id = azurerm_storage_account.durable_function_storage.id
    subresource_names              = ["file"]
    is_manual_connection           = false
  }
  private_dns_zone_group {
    name                 = azurerm_storage_account.durable_function_storage.name
    private_dns_zone_ids = [azurerm_private_dns_zone.dns_storage_file.id]
  }
}

resource "azurerm_private_endpoint" "durable_function_storage_queue" {
  name                = "mcd_agent_df_queue_endpoint"
  location            = azurerm_resource_group.mcd_agent_rg.location
  resource_group_name = azurerm_resource_group.mcd_agent_rg.name
  subnet_id           = azurerm_subnet.private_endpoint.id

  private_service_connection {
    name                           = "mcd_agent_df_queue"
    private_connection_resource_id = azurerm_storage_account.durable_function_storage.id
    subresource_names              = ["queue"]
    is_manual_connection           = false
  }
  private_dns_zone_group {
    name                 = azurerm_storage_account.durable_function_storage.name
    private_dns_zone_ids = [azurerm_private_dns_zone.dns_storage_queue.id]
  }
}

resource "azurerm_private_endpoint" "durable_function_storage_table" {
  name                = "mcd_agent_df_table_endpoint"
  location            = azurerm_resource_group.mcd_agent_rg.location
  resource_group_name = azurerm_resource_group.mcd_agent_rg.name
  subnet_id           = azurerm_subnet.private_endpoint.id

  private_service_connection {
    name                           = "mcd_agent_df_table"
    private_connection_resource_id = azurerm_storage_account.durable_function_storage.id
    subresource_names              = ["table"]
    is_manual_connection           = false
  }
  private_dns_zone_group {
    name                 = azurerm_storage_account.durable_function_storage.name
    private_dns_zone_ids = [azurerm_private_dns_zone.dns_storage_table.id]
  }
}

# Storage account used by the MC agent
resource "azurerm_storage_account" "mcd_agent_storage" {
  name                = local.agent_data_storage_account_name
  resource_group_name = local.resource_group_name
  location            = azurerm_resource_group.mcd_agent_rg.location

  account_tier                      = "Standard"
  account_replication_type          = var.storage_accounts_replication_type
  https_traffic_only_enabled        = true
  allow_nested_items_to_be_public   = false
  infrastructure_encryption_enabled = true

  # Using this approach to allow access from the IP address running Terraform,
  # this is required for the creation of the container below and run TF plan/apply
  # in the future.
  # You can manually disable public access completely after deploying this module,
  # just remember to restore this rule before executing TF again.
  public_network_access_enabled = true
  network_rules {
    default_action = "Deny"
    ip_rules       = [local.my_ip]
  }
}

# Container used by the MC agent
resource "azurerm_storage_container" "mcd_agent_storage_container" {
  name                  = local.agent_data_storage_container_name
  storage_account_name  = azurerm_storage_account.mcd_agent_storage.name
  container_access_type = "private"
}

# Private endpoint for the MC agent storage account
resource "azurerm_private_endpoint" "mcd_agent_storage_blob" {
  name                = "mcd_agent_storage_blob_endpoint"
  location            = azurerm_resource_group.mcd_agent_rg.location
  resource_group_name = azurerm_resource_group.mcd_agent_rg.name
  subnet_id           = azurerm_subnet.private_endpoint.id

  private_service_connection {
    name                           = "mcd_agent_storage_blob"
    private_connection_resource_id = azurerm_storage_account.mcd_agent_storage.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
  private_dns_zone_group {
    name                 = azurerm_storage_account.mcd_agent_storage.name
    private_dns_zone_ids = [azurerm_private_dns_zone.dns_storage_blob.id]
  }
}

# Lifecycle policy for the MC agent storage account
resource "azurerm_storage_management_policy" "mcd_agent_storage_lifecycle" {
  storage_account_id = azurerm_storage_account.mcd_agent_storage.id
  rule {
    name    = "obj-expiration"
    enabled = true
    filters {
      blob_types   = ["blockBlob", "appendBlob"]
      prefix_match = ["${azurerm_storage_container.mcd_agent_storage_container.name}/${local.agent_data_store_data_prefix}"]
    }
    actions {
      base_blob {
        delete_after_days_since_creation_greater_than = 90
      }
    }
  }
  rule {
    name    = "temp-expiration"
    enabled = true
    filters {
      blob_types   = ["blockBlob", "appendBlob"]
      prefix_match = ["${azurerm_storage_container.mcd_agent_storage_container.name}/${local.agent_data_store_data_prefix}/tmp"]
    }
    actions {
      base_blob {
        delete_after_days_since_creation_greater_than = 2
      }
    }
  }
}
