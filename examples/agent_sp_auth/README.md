# Agent with Service Principal Auth

This example deploys an Agent using OAuth 2.0 service principal authentication instead of the
default Function App host key.

## Prerequisites

See the Prerequisites subsection in the module.

Additionally, the deploying identity must have permissions to create app registrations and service
principals in Entra ID. Some tenants restrict this — check with your Azure AD administrator.

## Usage

```
terraform init
terraform plan
terraform apply
```

After applying, retrieve the service principal credentials to register the agent with Monte Carlo:

```
terraform output -json sp_credentials
```

These credentials (`tenant_id`, `client_id`, `client_secret`, `audience`) are provided when
registering the agent via the Monte Carlo UI or API with auth type `AZURE_FUNCTION_SERVICE_PRINCIPAL`.

**Note:** The client secret is stored in Terraform state. Use a secure backend (e.g. Terraform Cloud,
Azure Storage with encryption) to protect sensitive state data.

And don't forget to delete any resources when you're done (e.g. `terraform destroy`).
