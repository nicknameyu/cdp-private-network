locals {
  hub_vnet_id_parts = split("/", var.dns_server_subnet_id)
  hub_vnet_id       = join("/", [
    local.hub_vnet_id_parts[0],
    local.hub_vnet_id_parts[1],
    local.hub_vnet_id_parts[2],
    local.hub_vnet_id_parts[3],
    local.hub_vnet_id_parts[4],
    local.hub_vnet_id_parts[5],
    local.hub_vnet_id_parts[6],
    local.hub_vnet_id_parts[7],
    local.hub_vnet_id_parts[8],
  ])
}

############# HUB VNET DNS setting ###########
resource "azurerm_virtual_network_dns_servers" "hub" {
  count              = var.hub_vnet_default_dns ? 0:1
  virtual_network_id = local.hub_vnet_id
  dns_servers        = [module.dns_server.private_ip]
}