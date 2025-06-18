variable "disable_public_inbound" {
  description = <<EOF
    Disable inbound public network access. Setting this to true requires enabling the use of Azure Private Endpoints (Private Link).

    See details here: https://docs.getmontecarlo.com/docs/azure-private-link
  EOF
  type        = bool
  default     = false

}

variable "image" {
  description = "The image for the agent."
  type        = string
  default     = "montecarlodata/agent:latest-azure"
}

variable "location" {
  description = "The Azure location (region) to deploy resources into."
  type        = string
  default     = "EAST US"
}

variable "remote_upgradable" {
  description = <<EOF
    Allow the agent image to be remotely upgraded by Monte Carlo.

    Note that this sets a lifecycle to ignore any changes in Terraform to fields like the image used after the initial deployment.

    If not set to 'true' you will be responsible for upgrading the image (e.g. specifying a new tag) for any bug fixes and improvements.

    Changing this value after initial deployment will replace your agent and require (re)registration.
  EOF
  type        = bool
  default     = true
}

variable "subnet_id" {
  description = <<EOF
    Optionally connect the agent to a Virtual Network by specifying a subnet.

    Note that the subnet must already be delegated to "Microsoft.Web/serverFarms" or the deployment will fail.

    The ID can be retrieved using the command `az network vnet subnet list`.
  EOF
  type        = string
  default     = null
}

variable "existing_resource_group_name" {
  type        = string
  default     = null
  description = <<EOF
    The name of an existing resource group to use for the agent. If not specified a new resource group will be created.

    NOTE: We strongly recommend that you do not share resource groups with other jobs, as Monte Carlo might overwrite existing data.
  EOF
}

variable "existing_storage_accounts" {
  type = object({
    agent_durable_function_storage_account_name       = string # Storage account used by the Azure Durable Functions
    agent_durable_function_storage_account_access_key = string # The access key for the durable function storage account
    agent_durable_function_storage_account_share_name = string # The name of the storage account share for Azure Durable Functions
    agent_data_storage_account_name                   = string # Storage account used by the MC agent
    agent_data_storage_container_name                 = string # Container used by the MC agent
    private_access                                    = bool   # Whether the access to the storage accounts should use private networking. If true WEBSITE_CONTENTOVERVNET is set to 1 and WEBSITE_CONTENTSHARE to the name of the share.
  })
  sensitive   = true
  default     = null
  description = <<EOF
    Optionally use existing storage accounts for the agent. If not specified new storage accounts will be created.

    NOTE: We strongly recommend that you do not share storage accounts with other jobs, as Monte Carlo might overwrite existing data.
  EOF
}

