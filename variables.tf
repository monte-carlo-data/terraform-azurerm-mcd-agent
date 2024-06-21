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
  description = "The Azure location (region) to deploy the agent into."
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