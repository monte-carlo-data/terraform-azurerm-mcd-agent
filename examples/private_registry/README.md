# Agent from a Private Registry (ACR)

This example deploys an Agent whose image is pulled from an existing Azure Container Registry
(ACR) instead of Docker Hub. The Function App pulls with the agent's user-assigned managed
identity, and the module grants that identity `AcrPull` on the registry.

## Prerequisites

See the Prerequisites subsection in the module.

Additionally:

- An Azure Container Registry containing the agent image. For example, to copy a released image
  from Docker Hub:

  ```
  az acr import --name <ACR_NAME> \
    --source docker.io/montecarlodata/agent:<VERSION>-azure \
    --image mcd-agent/agent:<VERSION>-azure
  ```

- The deploying identity must be allowed to create role assignments on the registry (e.g. `Owner`
  or `User Access Administrator`).

## Usage

```
terraform init
terraform apply \
  -var acr_name=<ACR_NAME> \
  -var acr_resource_group_name=<ACR_RESOURCE_GROUP> \
  -var image=mcd-agent/agent:<VERSION>-azure
```

The `AcrPull` role assignment can take a few minutes to propagate. If the agent fails to start
because the first image pull was denied, restart the Function App once the role is in place.

See the "Private image registry" section in the module README for limitations (registry is fixed at
creation, Monte Carlo-initiated upgrades are not supported from a private registry).

And don't forget to delete any resources when you're done (e.g. `terraform destroy`).
