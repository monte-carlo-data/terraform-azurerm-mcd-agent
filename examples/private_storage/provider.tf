terraform {
  required_providers {
    # azapi is used to create the blob container and file share via the ARM
    # management plane, which is not subject to the storage account firewall.
    # This lets us keep the storage accounts fully private (no public access).
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azapi" {}
