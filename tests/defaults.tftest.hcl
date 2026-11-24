# Pins what the module plans for the Function App when no registry input is set, so upgrading the
# module is a no-op for existing deployments. Runs offline against mocked providers:
#   terraform init -backend=false && terraform test

mock_provider "azurerm" {}
mock_provider "azuread" {}
mock_provider "random" {}

# Fix the computed values that feed app settings so the whole map can be compared literally.
override_resource {
  target          = random_id.mcd_agent_id
  values          = { hex = "abcd1234" }
  override_during = plan
}
override_resource {
  target = azurerm_user_assigned_identity.mcd_agent_service_identity
  values = {
    id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/mcd"
    client_id = "00000000-0000-0000-0000-000000000001"
  }
  override_during = plan
}
override_resource {
  target          = azurerm_application_insights.mcd_agent_service_insights
  values          = { id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Insights/components/mcd" }
  override_during = plan
}

variables {
  # Every app setting except MCD_AGENT_WRAPPER_VERSION, which changes with each module release.
  expected_app_settings = {
    always_on                                                                      = "true"
    AzureWebJobsDisableHomepage                                                    = "true"
    FUNCTION_APP_EDIT_MODE                                                         = "readOnly"
    FUNCTIONS_EXTENSION_VERSION                                                    = "~4"
    DOCKER_REGISTRY_SERVER_URL                                                     = "https://docker.io"
    DOCKER_CUSTOM_IMAGE_NAME                                                       = "docker.io/montecarlodata/agent:latest-azure"
    WEBSITES_ENABLE_APP_SERVICE_STORAGE                                            = "false"
    AZURE_CLIENT_ID                                                                = "00000000-0000-0000-0000-000000000001"
    APPINSIGHTS_RESOURCE_ID                                                        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Insights/components/mcd"
    FUNCTIONS_WORKER_PROCESS_COUNT                                                 = "5"
    PYTHON_THREADPOOL_THREAD_COUNT                                                 = "5"
    AzureFunctionsJobHost__extensions__durableTask__maxConcurrentActivityFunctions = "20"
    AzureFunctionsJobHost__functionTimeout                                         = "00:15:00"
    MCD_AGENT_IMAGE_TAG                                                            = "montecarlodata/agent:latest-azure"
    MCD_AGENT_CLOUD_PLATFORM                                                       = "AZURE"
    MCD_AGENT_WRAPPER_TYPE                                                         = "TERRAFORM"
    MCD_STORAGE_ACCOUNT_NAME                                                       = "mcdagent1fsabcd1234"
    MCD_STORAGE_BUCKET_NAME                                                        = "mcdstore"
    MCD_AUTH_TYPE                                                                  = "AZURE_FUNCTION_APP_KEY"
    MCD_ADDITIONAL_ENV_VARS                                                        = "{}"
  }
  expected_app_setting_keys = [
    "APPINSIGHTS_RESOURCE_ID",
    "AZURE_CLIENT_ID",
    "AzureFunctionsJobHost__extensions__durableTask__maxConcurrentActivityFunctions",
    "AzureFunctionsJobHost__functionTimeout",
    "AzureWebJobsDisableHomepage",
    "DOCKER_CUSTOM_IMAGE_NAME",
    "DOCKER_REGISTRY_SERVER_URL",
    "FUNCTIONS_EXTENSION_VERSION",
    "FUNCTIONS_WORKER_PROCESS_COUNT",
    "FUNCTION_APP_EDIT_MODE",
    "MCD_ADDITIONAL_ENV_VARS",
    "MCD_AGENT_CLOUD_PLATFORM",
    "MCD_AGENT_IMAGE_TAG",
    "MCD_AGENT_IS_REMOTE_UPGRADABLE",
    "MCD_AGENT_WRAPPER_TYPE",
    "MCD_AGENT_WRAPPER_VERSION",
    "MCD_AUTH_TYPE",
    "MCD_STORAGE_ACCOUNT_NAME",
    "MCD_STORAGE_BUCKET_NAME",
    "PYTHON_THREADPOOL_THREAD_COUNT",
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE",
    "always_on",
  ]
}

run "default_remote_upgradable" {
  command = plan

  assert {
    condition     = length(azurerm_linux_function_app.mcd_agent_service) == 0 && length(azurerm_linux_function_app.mcd_agent_service_with_remote_upgrade_support) == 1
    error_message = "remote_upgradable defaults to true"
  }

  assert {
    condition     = sort(keys(azurerm_linux_function_app.mcd_agent_service_with_remote_upgrade_support[0].app_settings)) == sort(var.expected_app_setting_keys)
    error_message = "Default app settings keys changed"
  }

  assert {
    condition     = { for k, v in azurerm_linux_function_app.mcd_agent_service_with_remote_upgrade_support[0].app_settings : k => v if k != "MCD_AGENT_WRAPPER_VERSION" } == merge(var.expected_app_settings, { MCD_AGENT_IS_REMOTE_UPGRADABLE = "true" })
    error_message = "Default app settings values changed"
  }

  assert {
    condition     = azurerm_linux_function_app.mcd_agent_service_with_remote_upgrade_support[0].app_settings["DOCKER_REGISTRY_SERVER_URL"] == "https://docker.io"
    error_message = "Default DOCKER_REGISTRY_SERVER_URL changed"
  }

  assert {
    condition     = azurerm_linux_function_app.mcd_agent_service_with_remote_upgrade_support[0].app_settings["DOCKER_CUSTOM_IMAGE_NAME"] == "docker.io/montecarlodata/agent:latest-azure"
    error_message = "Default DOCKER_CUSTOM_IMAGE_NAME changed"
  }

  assert {
    condition     = azurerm_linux_function_app.mcd_agent_service_with_remote_upgrade_support[0].app_settings["MCD_AGENT_IMAGE_TAG"] == "montecarlodata/agent:latest-azure"
    error_message = "Default MCD_AGENT_IMAGE_TAG changed"
  }

  assert {
    condition = (
      azurerm_linux_function_app.mcd_agent_service_with_remote_upgrade_support[0].site_config[0].application_stack[0].docker[0].registry_url == "docker.io" &&
      azurerm_linux_function_app.mcd_agent_service_with_remote_upgrade_support[0].site_config[0].application_stack[0].docker[0].image_name == "montecarlodata/agent" &&
      azurerm_linux_function_app.mcd_agent_service_with_remote_upgrade_support[0].site_config[0].application_stack[0].docker[0].image_tag == "latest-azure"
    )
    error_message = "Default docker block changed"
  }

  assert {
    condition = (
      azurerm_linux_function_app.mcd_agent_service_with_remote_upgrade_support[0].site_config[0].application_stack[0].docker[0].registry_username == null &&
      azurerm_linux_function_app.mcd_agent_service_with_remote_upgrade_support[0].site_config[0].container_registry_use_managed_identity == null &&
      azurerm_linux_function_app.mcd_agent_service_with_remote_upgrade_support[0].site_config[0].container_registry_managed_identity_client_id == null
    )
    error_message = "Default must pull anonymously (no credentials, no managed identity)"
  }
}

run "default_not_remote_upgradable" {
  command = plan

  variables {
    remote_upgradable = false
  }

  assert {
    condition     = length(azurerm_linux_function_app.mcd_agent_service) == 1 && length(azurerm_linux_function_app.mcd_agent_service_with_remote_upgrade_support) == 0
    error_message = "remote_upgradable = false uses the non-upgradable resource"
  }

  assert {
    condition     = sort(keys(azurerm_linux_function_app.mcd_agent_service[0].app_settings)) == sort(var.expected_app_setting_keys)
    error_message = "Default app settings keys changed"
  }

  assert {
    condition     = { for k, v in azurerm_linux_function_app.mcd_agent_service[0].app_settings : k => v if k != "MCD_AGENT_WRAPPER_VERSION" } == merge(var.expected_app_settings, { MCD_AGENT_IS_REMOTE_UPGRADABLE = "false" })
    error_message = "Default app settings values changed"
  }

  assert {
    condition     = azurerm_linux_function_app.mcd_agent_service[0].app_settings["DOCKER_REGISTRY_SERVER_URL"] == "https://docker.io"
    error_message = "Default DOCKER_REGISTRY_SERVER_URL changed"
  }

  assert {
    condition     = azurerm_linux_function_app.mcd_agent_service[0].app_settings["DOCKER_CUSTOM_IMAGE_NAME"] == "docker.io/montecarlodata/agent:latest-azure"
    error_message = "Default DOCKER_CUSTOM_IMAGE_NAME changed"
  }

  assert {
    condition = (
      azurerm_linux_function_app.mcd_agent_service[0].site_config[0].application_stack[0].docker[0].registry_url == "docker.io" &&
      azurerm_linux_function_app.mcd_agent_service[0].site_config[0].application_stack[0].docker[0].image_name == "montecarlodata/agent" &&
      azurerm_linux_function_app.mcd_agent_service[0].site_config[0].application_stack[0].docker[0].image_tag == "latest-azure"
    )
    error_message = "Default docker block changed"
  }

  assert {
    condition = (
      azurerm_linux_function_app.mcd_agent_service[0].site_config[0].application_stack[0].docker[0].registry_username == null &&
      azurerm_linux_function_app.mcd_agent_service[0].site_config[0].container_registry_use_managed_identity == null &&
      azurerm_linux_function_app.mcd_agent_service[0].site_config[0].container_registry_managed_identity_client_id == null
    )
    error_message = "Default must pull anonymously (no credentials, no managed identity)"
  }
}
