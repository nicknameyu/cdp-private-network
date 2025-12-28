data "azurerm_subscription" "primary" {}
provider "azurerm" {
  alias           = "secondary"
  subscription_id = var.subscription_id != "" ? var.subscription_id : data.azurerm_subscription.primary.subscription_id
  features {}
}
