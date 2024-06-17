
resource "azurerm_resource_group" "cdp" {
  name     = var.resource_groups != null ? var.resource_groups.cdp_rg : "${var.owner}-cdp-env"
  location = var.location
  tags = var.tags
}

