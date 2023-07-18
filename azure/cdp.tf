
resource "azurerm_resource_group" "cdp" {
  name     = var.resource_groups.cdp_rg
  location = var.location
  tags = var.tags
}

