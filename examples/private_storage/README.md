# Agent Sample

This example deploys an Agent using a VNet and storage accounts with public access disabled.
Private endpoints are created for the storage accounts and the agent is configured to use them.

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