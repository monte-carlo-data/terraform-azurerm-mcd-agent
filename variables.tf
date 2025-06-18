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

    NOTE: It's recommended to use the resource group specified here only for MC agent related resources.
  EOF
}

variable "existing_storage_accounts" {
  type = object({
    durable_function_storage_account_name = string # Storage account used by the Azure Durable Functions
    agent_data_storage_account_name       = string # Storage account used by the MC agent
    agent_data_storage_container_name     = string # Container used by the MC agent
  })
  default     = null
  description = <<EOF
    Optionally use existing storage accounts for the agent. If not specified new storage accounts will be created.

    NOTE: It's recommended to use the storage accounts specified here only for the MC agent.
  EOF
}

variable "durable_function_storage_account_access_key" {
  type        = string
  default     = null
  sensitive   = true
  description = "The access key for the durable function storage account. Required if existing_storage_accounts is specified."
  validation {
    condition     = var.existing_storage_accounts == null || var.durable_function_storage_account_access_key != null
    error_message = "durable_function_storage_account_access_key is required if existing_storage_accounts is specified."
  }
}

variable "storage_accounts_private_access" {
  description = "Whether the storage accounts should be private. If true, the agent will use private endpoints to access them."
  type        = bool
  default     = false
}

variable "durable_function_storage_account_share_name" {
  description = "The name of the storage account share for Azure Durable Functions, if not specified it is assumed to be the name of the storage account."
  type        = string
  default     = null
}
