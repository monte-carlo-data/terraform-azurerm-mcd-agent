# Monte Carlo Azure Agent Module

This module deploys Monte Carlo's [containerized agent](https://hub.docker.com/r/montecarlodata/agent) on Azure
functions, along with storage, roles etc.

See [here](https://docs.getmontecarlo.com/docs/platform-architecture) for architecture details and alternative
deployment options.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) (>= 1.3)
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/).
  [Authentication reference](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- For `AZURE_FUNCTION_SERVICE_PRINCIPAL` auth: the deploying identity must have permissions to create
  app registrations and service principals in Entra ID

## Usage

Basic usage of this module:

```
module "apollo" {
  source = "monte-carlo-data/mcd-agent/azurerm"
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
```

After which you must register your agent with Monte Carlo. See
[here](https://docs.getmontecarlo.com/docs/create-and-register-an-azure-agent) for more details, options, and
documentation.

### Service Principal Auth

To use OAuth 2.0 service principal authentication instead of the default Function App host key:

```
module "apollo" {
  source    = "monte-carlo-data/mcd-agent/azurerm"
  auth_type = "AZURE_FUNCTION_SERVICE_PRINCIPAL"
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
```

This creates Entra ID app registrations, enables Easy Auth on the Function App, and outputs the
credentials needed to register the agent with auth type `AZURE_FUNCTION_SERVICE_PRINCIPAL`.

**Note:** The client secret is stored in Terraform state. Use a secure backend to protect sensitive
state data.

Note that this module is configured to delete all resources when the resource group is deleted (e.g. via terraform
destroy). Please take appropriate measures and review your resources before doing so.
See [here](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/features-block#prevent_deletion_if_contains_resources)
for additional details.

## Inputs

| **Name**                     | **Description**                                                                                                                                                                                                                                                                                                                                                                                                                      | **Type** | **Default**                       |
|------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|-----------------------------------|
| auth_type                    | The authentication method for the Monte Carlo Data Collector to invoke the agent. `AZURE_FUNCTION_APP_KEY` uses the Function App's host key. `AZURE_FUNCTION_SERVICE_PRINCIPAL` uses OAuth 2.0 client credentials grant with Entra ID.                                                                                                                                                                                               | string   | AZURE_FUNCTION_APP_KEY            |
| disable_public_inbound       | Disable inbound public network access. Setting this to true requires enabling the use of Azure Private Endpoints (Private Link). See details here: https://docs.getmontecarlo.com/docs/azure-private-link                                                                                                                                                                                                                            | bool     | false                             |
| image                        | The image for the agent.                                                                                                                                                                                                                                                                                                                                                                                                             | string   | montecarlodata/agent:latest-azure |
| location                     | The Azure location (region) to deploy the agent into.                                                                                                                                                                                                                                                                                                                                                                                | string   | EAST US                           |
| remote_upgradable            | Allow the agent image to be remotely upgraded by Monte Carlo. Note that this sets a lifecycle to ignore any changes in Terraform to fields like the image used after the initial deployment. If not set to 'true' you will be responsible for upgrading the image (e.g. specifying a new tag) for any bug fixes and improvements. Changing this value after initial deployment will replace your agent and require (re)registration. | bool     | true                              |
| subnet_id                    | Optionally connect the agent to a Virtual Network by specifying a subnet. Note that the subnet must already be delegated to "Microsoft.Web/serverFarms" or the deployment will fail. The ID can be retrieved using the command `az network vnet subnet list`.                                                                                                                                                                        | string   | null                              |
| existing_resource_group_name | Optionally use an existing resource group for the agent. If not specified a new resource group will be created. NOTE: We strongly recommend that you do not share resource groups with other jobs, as Monte Carlo might overwrite existing data.                                                                                                                                                                                     | string   | null                              |
| existing_storage_accounts    | Optionally use existing storage accounts for the agent. If not specified new storage accounts will be created. NOTE: We strongly recommend that you do not share storage accounts with other jobs, as Monte Carlo might overwrite existing data.                                                                                                                                                                                     | object   | null                              |

## Outputs

| **Name**                                | **Description**                                                               |
|-----------------------------------------|-------------------------------------------------------------------------------|
| mcd_agent_function_url                  | The URL for the agent.                                                        |
| mcd_agent_function_name                 | Agent function name.                                                          |
| mcd_agent_resource_group_name           | Agent service resource group.                                                 |
| mcd_agent_service_identity_principal_id | Agent service principal id.                                                   |
| mcd_agent_auth_type                     | The auth type configured for this agent deployment.                           |
| mcd_agent_sp_tenant_id                  | Entra ID tenant ID for service principal auth. Null if using app key auth.    |
| mcd_agent_sp_client_id                  | Caller service principal client ID. Null if using app key auth.               |
| mcd_agent_sp_client_secret              | Caller service principal client secret (sensitive). Null if using app key auth.|
| mcd_agent_sp_audience                   | Function App audience URI for service principal auth. Null if using app key auth.|

## Releases and Development

The README and sample agent in the `examples/agent` directory is a good starting point to familiarize
yourself with using the agent.

Note that all Terraform files must conform to the standards of `terraform fmt` and
the [standard module structure](https://developer.hashicorp.com/terraform/language/modules/develop).
CircleCI will sanity check formatting and for valid tf config files.
It is also recommended you use Terraform Cloud as a backend.
Otherwise, as normal, please follow Monte Carlo's code guidelines during development and review.

When ready to release simply add a new version tag, e.g. v0.0.42, and push that tag to GitHub.
See additional
details [here](https://developer.hashicorp.com/terraform/registry/modules/publish#releasing-new-versions).

## License

See [LICENSE](LICENSE) for more information.

## Security

See [SECURITY](SECURITY.md) for more information.