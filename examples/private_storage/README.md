# Agent Sample

This example deploys an Agent using a VNet and storage accounts using private access.
Private endpoints are created for the storage accounts and the agent is configured to use them.

The Storage Accounts in this example are kept fully private (`public_network_access_enabled = false`):
they are only reachable through the private endpoints. This is possible because the file share and
blob container are created with the [`azapi`](https://registry.terraform.io/providers/Azure/azapi/latest)
provider, which manages them through the Azure Resource Manager (ARM) management plane rather than the
storage data plane. Management-plane calls are not subject to the storage account firewall, so the
machine running Terraform does not need any network path to the storage accounts.

> The `azurerm_storage_share` / `azurerm_storage_container` resources operate over the storage data
> plane (`*.file.core.windows.net` / `*.blob.core.windows.net`), so with a private account they
> would require Terraform to run from a network with access to the account (e.g. a subnet/private
> endpoint), or a temporary public firewall rule allowing the runner's IP. Using `azapi` avoids that
> entirely. If you prefer the `azurerm`-only approach, you can instead run Terraform from a subnet
> with access to the Storage Account, or remove the storage account creation from this example and
> pass them in as input variables.

Note that there are additional requirements and limitations for using private storage accounts 
with Monte Carlo. Please review the docs [here](https://mc-d.io/LgZYUfJ) for further details.

## Prerequisites

See the Prerequisites subsection in the module.

## Usage

To provision this example and access (test) the agent locally:

```
terraform init
terraform apply
```

See [here](https://github.com/monte-carlo-data/apollo-agent) for agent usage and docs. You should be able to use any
endpoint as documented.

And don't forget to delete any resources when you're done (e.g. `terraform destroy`).

## Addendum

During development, you might want configure Terraform Cloud as the backend. To do so you can add the following snippet:

```
terraform {
  cloud {
    organization = "<org>"

    workspaces {
      name = "<workspace>"
    }
  }
}
```

This also requires you to execute `terraform login` before initializing. You will also either have to update the
working directory to include the agent module or set the execution mode to "Local".
