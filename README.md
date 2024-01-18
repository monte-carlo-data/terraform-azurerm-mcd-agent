# Monte Carlo Azure Agent Module (Beta)

This module deploys Monte Carlo's [containerized agent](https://hub.docker.com/r/montecarlodata/agent) (Beta) on Azure
functions, along with storage, roles etc.

See [here](https://docs.getmontecarlo.com/docs/platform-architecture) for architecture details and alternative
deployment options.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) (>= 1.3)
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/).
  [Authentication reference](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

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

Note that this module is configured to delete all resources when the resource group is deleted (e.g. via terraform
destroy). Please take appropriate measures and review your resources before doing so.
See [here](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/features-block#prevent_deletion_if_contains_resources)
for additional details.

## Inputs

| **Name**          | **Description**                                                                                                                                                                                                                                                                                                                                                                                                                      | **Type** | **Default**                       |
|-------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|-----------------------------------|
| location          | The Azure location (region) to deploy the agent into.                                                                                                                                                                                                                                                                                                                                                                                | string   | EAST US                           |
| image             | The image for the agent.                                                                                                                                                                                                                                                                                                                                                                                                             | string   | montecarlodata/agent:latest-azure |
| remote_upgradable | Allow the agent image to be remotely upgraded by Monte Carlo. Note that this sets a lifecycle to ignore any changes in Terraform to fields like the image used after the initial deployment. If not set to 'true' you will be responsible for upgrading the image (e.g. specifying a new tag) for any bug fixes and improvements. Changing this value after initial deployment will replace your agent and require (re)registration. | bool     | true                              |

## Outputs

| **Name**                      | **Description**               |
|-------------------------------|-------------------------------|
| mcd_agent_function_url        | The URL for the agent.        |
| mcd_agent_function_name       | Agent function name.          |
| mcd_agent_resource_group_name | Agent service resource group. |

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