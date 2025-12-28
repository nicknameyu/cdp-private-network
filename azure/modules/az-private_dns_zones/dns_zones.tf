############### Resource group ################
resource "azurerm_resource_group" "dns" {
  count    = var.create_resource_group ? 1:0
  name     = var.resource_group_name
  provider = azurerm.secondary
  location = var.location
  tags     = var.tags
}
data "azurerm_resource_group" "dns" {
  count    = var.create_resource_group ? 0:1
  name     = var.resource_group_name
  provider = azurerm.secondary
}
locals {
  resource_group_name = var.create_resource_group ? azurerm_resource_group.dns[0].name : data.azurerm_resource_group.dns[0].name
}

################ Private DNS zones ###############

resource "azurerm_private_dns_zone" "dns" {
  for_each            = local.private_dns_zones
  name                = each.value
  resource_group_name = local.resource_group_name
  provider            = azurerm.secondary
  tags                = var.tags
}

output "private_dns_zones" {
  value = { for k, s in azurerm_private_dns_zone.dns : k => s.id }
}

############## Private DNS Zone Links ##############
locals {
  matrix = {
    for vnet_name, vnet_id in var.vnet_ids :
    vnet_name => {
      for zone_name, zone_value in azurerm_private_dns_zone.dns :
      "${vnet_name}-${zone_name}" => {
        vnet_id = vnet_id
        dns_zone = zone_value
      }
    }
  }

  # flatten inner maps
  vnet_links = merge([
    for e in local.matrix : e
  ]...)
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns" {
  for_each              = local.vnet_links
  name                  = each.key
  resource_group_name   = local.resource_group_name
  provider              = azurerm.secondary
  private_dns_zone_name = each.value.dns_zone.name
  virtual_network_id    = each.value.vnet_id
}