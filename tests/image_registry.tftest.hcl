# Private image registry inputs. Runs offline against mocked providers:
#   terraform init -backend=false && terraform test

mock_provider "azurerm" {}
mock_provider "azuread" {}
mock_provider "random" {}

override_resource {
  target = azurerm_user_assigned_identity.mcd_agent_service_identity
  values = {
    id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/mcd"
    client_id    = "00000000-0000-0000-0000-000000000001"
    principal_id = "00000000-0000-0000-0000-000000000002"
  }
  override_during = plan
}

variables {
  acr_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.ContainerRegistry/registries/mcdtest"
}

run "acr_managed_identity" {
  command = plan

  variables {
    remote_upgradable                   = false
    image                               = "mcd-agent/agent:1.2.3-azure"
    image_registry                      = "mcdtest.azurecr.io"
    image_registry_use_managed_identity = true
    image_registry_acr_id               = var.acr_id
  }

  assert {
    condition     = azurerm_linux_function_app.mcd_agent_service[0].site_config[0].application_stack[0].docker[0].registry_url == "mcdtest.azurecr.io"
    error_message = "docker registry_url should be the ACR host"
  }

  assert {
    condition = (
      azurerm_linux_function_app.mcd_agent_service[0].site_config[0].application_stack[0].docker[0].image_name == "mcd-agent/agent" &&
      azurerm_linux_function_app.mcd_agent_service[0].site_config[0].application_stack[0].docker[0].image_tag == "1.2.3-azure"
    )
    error_message = "image name/tag should come from var.image"
  }

  assert {
    condition = (
      azurerm_linux_function_app.mcd_agent_service[0].app_settings["DOCKER_REGISTRY_SERVER_URL"] == "https://mcdtest.azurecr.io" &&
      azurerm_linux_function_app.mcd_agent_service[0].app_settings["DOCKER_CUSTOM_IMAGE_NAME"] == "mcdtest.azurecr.io/mcd-agent/agent:1.2.3-azure"
    )
    error_message = "registry app settings should point at the ACR"
  }

  assert {
    condition = (
      azurerm_linux_function_app.mcd_agent_service[0].site_config[0].container_registry_use_managed_identity == true &&
      azurerm_linux_function_app.mcd_agent_service[0].site_config[0].container_registry_managed_identity_client_id == "00000000-0000-0000-0000-000000000001" &&
      azurerm_linux_function_app.mcd_agent_service[0].site_config[0].application_stack[0].docker[0].registry_username == null
    )
    error_message = "should pull with the agent's user-assigned identity and no credentials"
  }

  assert {
    condition = (
      length(azurerm_role_assignment.mcd_agent_acr_pull_ra) == 1 &&
      azurerm_role_assignment.mcd_agent_acr_pull_ra[0].scope == var.acr_id &&
      azurerm_role_assignment.mcd_agent_acr_pull_ra[0].role_definition_name == "AcrPull" &&
      azurerm_role_assignment.mcd_agent_acr_pull_ra[0].principal_id == "00000000-0000-0000-0000-000000000002"
    )
    error_message = "should grant AcrPull on the ACR to the agent identity"
  }
}

run "managed_identity_without_role_assignment" {
  command = plan

  variables {
    image_registry                      = "mcdtest.azurecr.io"
    image_registry_use_managed_identity = true
  }

  assert {
    condition = (
      azurerm_linux_function_app.mcd_agent_service_with_remote_upgrade_support[0].site_config[0].container_registry_use_managed_identity == true &&
      length(azurerm_role_assignment.mcd_agent_acr_pull_ra) == 0
    )
    error_message = "managed identity pull without image_registry_acr_id should not create a role assignment"
  }
}

run "username_password" {
  command = plan

  variables {
    image_registry          = "registry.example.com"
    image_registry_username = "puller"
    image_registry_password = "not-a-real-secret"
  }

  assert {
    condition = (
      azurerm_linux_function_app.mcd_agent_service_with_remote_upgrade_support[0].site_config[0].application_stack[0].docker[0].registry_url == "registry.example.com" &&
      azurerm_linux_function_app.mcd_agent_service_with_remote_upgrade_support[0].site_config[0].application_stack[0].docker[0].registry_username == "puller" &&
      nonsensitive(azurerm_linux_function_app.mcd_agent_service_with_remote_upgrade_support[0].site_config[0].application_stack[0].docker[0].registry_password) == "not-a-real-secret" &&
      azurerm_linux_function_app.mcd_agent_service_with_remote_upgrade_support[0].site_config[0].container_registry_use_managed_identity == null
    )
    error_message = "should pull from the registry with the given credentials"
  }
}

run "rejects_registry_with_scheme" {
  command = plan

  variables {
    image_registry = "https://mcdtest.azurecr.io"
  }

  expect_failures = [var.image_registry]
}

run "rejects_username_without_password" {
  command = plan

  variables {
    image_registry          = "registry.example.com"
    image_registry_username = "puller"
  }

  expect_failures = [azurerm_linux_function_app.mcd_agent_service_with_remote_upgrade_support]
}

run "rejects_credentials_with_managed_identity" {
  command = plan

  variables {
    remote_upgradable                   = false
    image_registry                      = "mcdtest.azurecr.io"
    image_registry_username             = "puller"
    image_registry_password             = "not-a-real-secret"
    image_registry_use_managed_identity = true
  }

  expect_failures = [azurerm_linux_function_app.mcd_agent_service]
}

run "rejects_acr_id_without_managed_identity" {
  command = plan

  variables {
    image_registry        = "mcdtest.azurecr.io"
    image_registry_acr_id = var.acr_id
  }

  expect_failures = [azurerm_linux_function_app.mcd_agent_service_with_remote_upgrade_support]
}

run "rejects_managed_identity_with_docker_hub" {
  command = plan

  variables {
    image_registry_use_managed_identity = true
  }

  expect_failures = [azurerm_linux_function_app.mcd_agent_service_with_remote_upgrade_support]
}

run "rejects_managed_identity_with_docker_hub_alias" {
  command = plan

  variables {
    image_registry                      = "Index.Docker.io"
    image_registry_use_managed_identity = true
  }

  expect_failures = [azurerm_linux_function_app.mcd_agent_service_with_remote_upgrade_support]
}

run "rejects_empty_username" {
  command = plan

  variables {
    image_registry          = "registry.example.com"
    image_registry_username = ""
    image_registry_password = "not-a-real-secret"
  }

  expect_failures = [var.image_registry_username]
}
