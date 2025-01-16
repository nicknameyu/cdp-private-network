terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0.1"
    }
  }
}
provider "azurerm" {
  subscription_id = var.subscription_id
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }

    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# In many customer setup, private DNS zone is centrally managed in a different subscription. This provider definition enable the template to create private DNS zone resources in another subscription.
provider "azurerm" {
  alias           = "secondary"
  subscription_id = var.dns_zone_subscription_id == null ? var.subscription_id : var.dns_zone_subscription_id
  features {}
}