locals {
  # Wrapper metadata
  mcd_wrapper_version       = "0.1.1"
  mcd_agent_platform        = "AZURE"
  mcd_agent_service_name    = "REMOTE_AGENT"
  mcd_agent_deployment_type = "TERRAFORM"

  # Docker properties
  docker_scheme       = "https"
  docker_registry_url = "docker.io"

  mcd_agent_name = split(":", var.image)[0]
  mcd_agent_tag  = split(":", var.image)[1]

  # Service properties
  mcd_agent_naming_prefix = "mcd-agent"

  # Data store properties
  mcd_agent_store_container_name = "mcdstore"
  mcd_agent_store_data_prefix    = "mcd"

  # Function properties
  mcd_agent_function_name  = "${local.mcd_agent_naming_prefix}-service-${random_id.mcd_agent_id.hex}"
  mcd_agent_identity_types = "UserAssigned"
  mcd_agent_function_app_settings = {
    # Function configuration
    always_on                                                                      = true
    AzureWebJobsDisableHomepage                                                    = true
    FUNCTION_APP_EDIT_MODE                                                         = "readOnly"
    FUNCTIONS_EXTENSION_VERSION                                                    = "~4"
    DOCKER_REGISTRY_SERVER_URL                                                     = "${local.docker_scheme}://${local.docker_registry_url}"
    DOCKER_CUSTOM_IMAGE_NAME                                                       = "${local.docker_registry_url}/${var.image}"
    WEBSITES_ENABLE_APP_SERVICE_STORAGE                                            = false
    AZURE_CLIENT_ID                                                                = azurerm_user_assigned_identity.mcd_agent_service_identity.client_id
    APPINSIGHTS_RESOURCE_ID                                                        = azurerm_application_insights.mcd_agent_service_insights.id
    FUNCTIONS_WORKER_PROCESS_COUNT                                                 = 5
    PYTHON_THREADPOOL_THREAD_COUNT                                                 = 5
    AzureFunctionsJobHost__extensions__durableTask__maxConcurrentActivityFunctions = 20
    AzureFunctionsJobHost__functionTimeout                                         = "00:15:00"

    # MC properties and configuration
    MCD_AGENT_IMAGE_TAG       = var.image
    MCD_AGENT_CLOUD_PLATFORM  = local.mcd_agent_platform
    MCD_AGENT_WRAPPER_TYPE    = local.mcd_agent_deployment_type
    MCD_AGENT_WRAPPER_VERSION = local.mcd_wrapper_version
    MCD_AGENT_IS_REMOTE_UPGRADABLE : var.remote_upgradable ? "true" : "false"
    MCD_STORAGE_ACCOUNT_NAME = azurerm_storage_account.mcd_agent_storage[1].name
    MCD_STORAGE_BUCKET_NAME  = azurerm_storage_container.mcd_agent_storage_container.name
  }
}

resource "random_id" "mcd_agent_id" {
  byte_length = 4
}

## ---------------------------------------------------------------------------------------------------------------------
## Agent Resources
## MCD agent core components: Azure function for service execution and storage for troubleshooting and temporary data.
## See details here: https://docs.getmontecarlo.com/docs/platform-architecture#customer-hosted-agent--object-storage-deployment
## ---------------------------------------------------------------------------------------------------------------------

resource "azurerm_resource_group" "mcd_agent_rg" {
  name     = "${local.mcd_agent_naming_prefix}-group-${random_id.mcd_agent_id.hex}"
  location = var.location
}

resource "azurerm_storage_account" "mcd_agent_storage" {
  count               = 2
  name                = "mcdagent${count.index}fs${random_id.mcd_agent_id.hex}"
  resource_group_name = azurerm_resource_group.mcd_agent_rg.name
  location            = azurerm_resource_group.mcd_agent_rg.location

  account_tier                      = "Standard"
  account_replication_type          = "GRS"
  enable_https_traffic_only         = true
  allow_nested_items_to_be_public   = false
  infrastructure_encryption_enabled = true
} # Key: Index 0 - Function Storage (e.g. durable function data). Index 1 - App storage (e.g. MC sampling)

resource "azurerm_storage_container" "mcd_agent_storage_container" {
  name                  = local.mcd_agent_store_container_name
  storage_account_name  = azurerm_storage_account.mcd_agent_storage[1].name
  container_access_type = "private"
}

resource "azurerm_storage_management_policy" "mcd_agent_storage_lifecycle" {
  storage_account_id = azurerm_storage_account.mcd_agent_storage[1].id
  rule {
    name    = "obj-expiration"
    enabled = true
    filters {
      blob_types   = ["blockBlob", "appendBlob"]
      prefix_match = ["${azurerm_storage_container.mcd_agent_storage_container.name}/${local.mcd_agent_store_data_prefix}"]
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
      prefix_match = ["${azurerm_storage_container.mcd_agent_storage_container.name}/${local.mcd_agent_store_data_prefix}/tmp"]
    }
    actions {
      base_blob {
        delete_after_days_since_creation_greater_than = 2
      }
    }
  }
}

resource "azurerm_service_plan" "mcd_agent_service_plan" {
  name                = "${local.mcd_agent_naming_prefix}-service-plan"
  resource_group_name = azurerm_resource_group.mcd_agent_rg.name
  location            = azurerm_resource_group.mcd_agent_rg.location

  os_type  = "Linux"
  sku_name = "EP1"
}

resource "azurerm_log_analytics_workspace" "mcd_agent_service_analytics_workspace" {
  name                = "analytics-workspace-${local.mcd_agent_function_name}"
  resource_group_name = azurerm_resource_group.mcd_agent_rg.name
  location            = azurerm_resource_group.mcd_agent_rg.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "mcd_agent_service_insights" {
  name                = "application-insights-${local.mcd_agent_function_name}"
  resource_group_name = azurerm_resource_group.mcd_agent_rg.name
  location            = azurerm_resource_group.mcd_agent_rg.location
  workspace_id        = azurerm_log_analytics_workspace.mcd_agent_service_analytics_workspace.id
  application_type    = "other"
}

resource "azurerm_user_assigned_identity" "mcd_agent_service_identity" {
  name                = "${local.mcd_agent_function_name}-identity"
  resource_group_name = azurerm_resource_group.mcd_agent_rg.name
  location            = azurerm_resource_group.mcd_agent_rg.location
}

resource "azurerm_role_assignment" "mcd_agent_storage_cont_ra" {
  scope                = azurerm_storage_account.mcd_agent_storage[1].id
  principal_id         = azurerm_user_assigned_identity.mcd_agent_service_identity.principal_id
  role_definition_name = "Storage Blob Data Contributor"
}

resource "azurerm_role_assignment" "mcd_agent_storage_key_ra" {
  scope                = azurerm_storage_account.mcd_agent_storage[1].id
  principal_id         = azurerm_user_assigned_identity.mcd_agent_service_identity.principal_id
  role_definition_name = "Storage Account Key Operator Service Role"
}

resource "azurerm_role_assignment" "mcd_agent_service_ra" {
  scope                = var.remote_upgradable ? azurerm_linux_function_app.mcd_agent_service_with_remote_upgrade_support[0].id : azurerm_linux_function_app.mcd_agent_service[0].id
  principal_id         = azurerm_user_assigned_identity.mcd_agent_service_identity.principal_id
  role_definition_name = var.remote_upgradable ? "Contributor" : "Reader"
}

resource "azurerm_role_assignment" "mcd_agent_logs_ra" {
  scope                = azurerm_application_insights.mcd_agent_service_insights.id
  principal_id         = azurerm_user_assigned_identity.mcd_agent_service_identity.principal_id
  role_definition_name = "Log Analytics Reader"
}

resource "azurerm_linux_function_app" "mcd_agent_service" {
  count               = var.remote_upgradable ? 0 : 1
  name                = local.mcd_agent_function_name
  resource_group_name = azurerm_resource_group.mcd_agent_rg.name
  location            = azurerm_resource_group.mcd_agent_rg.location

  storage_account_name       = azurerm_storage_account.mcd_agent_storage[0].name
  storage_account_access_key = azurerm_storage_account.mcd_agent_storage[0].primary_access_key
  service_plan_id            = azurerm_service_plan.mcd_agent_service_plan.id

  site_config {
    application_insights_key               = azurerm_application_insights.mcd_agent_service_insights.instrumentation_key
    application_insights_connection_string = azurerm_application_insights.mcd_agent_service_insights.connection_string
    application_stack {
      docker {
        registry_url = local.docker_registry_url
        image_name   = local.mcd_agent_name
        image_tag    = local.mcd_agent_tag
      }
    }
  }
  https_only = true
  identity {
    type         = local.mcd_agent_identity_types
    identity_ids = [azurerm_user_assigned_identity.mcd_agent_service_identity.id]
  }
  app_settings = local.mcd_agent_function_app_settings
  lifecycle {
    ignore_changes = [
      site_config[0].application_stack[0].docker[0].registry_url,
      app_settings["DOCKER_REGISTRY_SERVER_URL"],
      app_settings["FUNCTIONS_EXTENSION_VERSION"]
    ]
  } # Necessary due to a bug in the azure terraform provider where these values are re-applied sans scheme in every run
}

# Terraform lifecycle meta arguments do not support conditions so two copies of the resource are required to ignore
# remote (agent sourced) image upgrades.
resource "azurerm_linux_function_app" "mcd_agent_service_with_remote_upgrade_support" {
  count               = var.remote_upgradable ? 1 : 0
  name                = local.mcd_agent_function_name
  resource_group_name = azurerm_resource_group.mcd_agent_rg.name
  location            = azurerm_resource_group.mcd_agent_rg.location

  storage_account_name       = azurerm_storage_account.mcd_agent_storage[0].name
  storage_account_access_key = azurerm_storage_account.mcd_agent_storage[0].primary_access_key
  service_plan_id            = azurerm_service_plan.mcd_agent_service_plan.id

  site_config {
    application_insights_key               = azurerm_application_insights.mcd_agent_service_insights.instrumentation_key
    application_insights_connection_string = azurerm_application_insights.mcd_agent_service_insights.connection_string
    application_stack {
      docker {
        registry_url = local.docker_registry_url
        image_name   = local.mcd_agent_name
        image_tag    = local.mcd_agent_tag
      }
    }
  }
  https_only = true
  identity {
    type         = local.mcd_agent_identity_types
    identity_ids = [azurerm_user_assigned_identity.mcd_agent_service_identity.id]
  }
  app_settings = local.mcd_agent_function_app_settings
  lifecycle {
    ignore_changes = [
      site_config[0].application_stack[0],
      app_settings["DOCKER_REGISTRY_SERVER_URL"],
      app_settings["FUNCTIONS_EXTENSION_VERSION"],
      app_settings["DOCKER_CUSTOM_IMAGE_NAME"],
      app_settings["MCD_AGENT_IMAGE_TAG"],
      app_settings["FUNCTIONS_WORKER_PROCESS_COUNT"],
      app_settings["PYTHON_THREADPOOL_THREAD_COUNT"],
      app_settings["AzureFunctionsJobHost__extensions__durableTask__maxConcurrentActivityFunctions"],
      app_settings["AzureFunctionsJobHost__functionTimeout"],
    ]
  }
}
