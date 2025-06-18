variable "location" {
  description = "The Azure location (region) to deploy the agent into."
  type        = string
  default     = "EAST US"
}

variable "vnet_address_space" {
  description = "The address space for the VNet."
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "vnet_default_subnet_address_prefixes" {
  description = "The address prefixes for the default subnet."
  type        = list(string)
  default     = ["10.0.0.0/24"]
}

variable "vnet_agent_subnet_address_prefixes" {
  description = "The address prefixes for the agent subnet."
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "vnet_private_endpoint_subnet_address_prefixes" {
  description = "The address prefixes for the private endpoint subnet."
  type        = list(string)
  default     = ["10.0.2.0/24"]
}

variable "storage_accounts_replication_type" {
  description = "The replication type for the storage accounts."
  type        = string
  default     = "GRS"
}