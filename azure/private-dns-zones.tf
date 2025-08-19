############# Private DNS Zone ############
resource "azurerm_resource_group" "dns" {
  count    = var.dns_zone_subscription_id == null ? 0:1
  name     = "${var.owner}-dns-zone"
  location = var.location
  provider = azurerm.secondary
  tags     = var.tags
}
locals {
  dns_zone_resource_group_id = var.dns_zone_subscription_id == null ? azurerm_resource_group.network.id : azurerm_resource_group.dns[0].id
}

resource "azurerm_private_dns_zone" "aks" {
  name                = "privatelink.${var.location}.azmk8s.io"
  resource_group_name = var.dns_zone_subscription_id == null ? azurerm_resource_group.network.name : azurerm_resource_group.dns[0].name
  provider            = azurerm.secondary
  tags                = var.tags
}
resource "azurerm_private_dns_zone_virtual_network_link" "cdp_aks" {
  name                  = "cdp_vnet"
  resource_group_name   = var.dns_zone_subscription_id == null ? azurerm_resource_group.network.name : azurerm_resource_group.dns[0].name
  provider              = azurerm.secondary
  private_dns_zone_name = azurerm_private_dns_zone.aks.name
  virtual_network_id    = azurerm_virtual_network.cdp.id
}

resource "azurerm_private_dns_zone" "pg_flx" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = var.dns_zone_subscription_id == null ? azurerm_resource_group.network.name : azurerm_resource_group.dns[0].name
  provider            = azurerm.secondary
  tags                = var.tags
}
resource "azurerm_private_dns_zone_virtual_network_link" "pg_flx" {
  name                  = "cdp_vnet"
  resource_group_name = var.dns_zone_subscription_id == null ? azurerm_resource_group.network.name : azurerm_resource_group.dns[0].name
  provider            = azurerm.secondary
  private_dns_zone_name = azurerm_private_dns_zone.pg_flx.name
  virtual_network_id    = azurerm_virtual_network.cdp.id
}
resource "azurerm_private_dns_zone" "storage" {
  name                = "privatelink.dfs.core.windows.net"
  resource_group_name = var.dns_zone_subscription_id == null ? azurerm_resource_group.network.name : azurerm_resource_group.dns[0].name
  provider            = azurerm.secondary
  tags                = var.tags
}
resource "azurerm_private_dns_zone_virtual_network_link" "storage" {
  name                  = "hub_vnet"
  resource_group_name   = var.dns_zone_subscription_id == null ? azurerm_resource_group.network.name : azurerm_resource_group.dns[0].name
  provider              =  azurerm.secondary
  private_dns_zone_name = azurerm_private_dns_zone.storage.name
  virtual_network_id    = azurerm_virtual_network.hub.id
}
resource "azurerm_private_dns_zone" "mysql" {
  name                = "privatelink.mysql.database.azure.com"
  resource_group_name = var.dns_zone_subscription_id == null ? azurerm_resource_group.network.name : azurerm_resource_group.dns[0].name
  provider            = azurerm.secondary
  tags                = var.tags
}
resource "azurerm_private_dns_zone_virtual_network_link" "mysql" {
  name                  = "cdp_vnet"
  resource_group_name = var.dns_zone_subscription_id == null ? azurerm_resource_group.network.name : azurerm_resource_group.dns[0].name
  provider            = azurerm.secondary
  private_dns_zone_name = azurerm_private_dns_zone.mysql.name
  virtual_network_id    = azurerm_virtual_network.cdp.id
}
output "private_dns_zones" {
  value = {
    aksPrivateDNSZoneID      = azurerm_private_dns_zone.aks.id
    postgresPrivateDNSZoneID = azurerm_private_dns_zone.pg_flx.id
    mysqlPrivateDNSZoneID     = azurerm_private_dns_zone.mysql.id
  }
}
