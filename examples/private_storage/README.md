# Agent Sample

This example deploys an Agent using a VNet and storage accounts using private access.
Private endpoints are created for the storage accounts and the agent is configured to use them.

Please note that Storage Accounts are configured with public access enabled only from the IP
address running Terraform. 
This is due to a limitation in the way the Azure provider for TF works, in order to create
shares or containers it needs access to the storage account.
You can remove this rule if you run TF from a subnet with access to the Storage Account or you 
can update this module to remove the creation of the storage accounts (and the corresponding 
share and container) and receive them as input variables.

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