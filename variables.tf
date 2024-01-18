variable "location" {
  description = "The Azure location (region) to deploy the agent into."
  type        = string
  default     = "EAST US"
}

variable "image" {
  description = "The image for the agent."
  type        = string
  default     = "montecarlodata/agent:latest-azure"
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