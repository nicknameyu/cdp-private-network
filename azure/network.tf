############### Hub VNET #############
resource "azurerm_resource_group" "network" {
  name     = var.resource_groups.network_rg
  location = var.location
  tags = var.tags
}
resource "azurerm_virtual_network" "hub" {
  name                = var.hub_vnet_name
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
  address_space       = [var.hub_cidr]
  tags                = var.tags
}
resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = local.hub_subnets.AzureFirewallSubnet
}

resource "azurerm_subnet" "core" {
  name                 = "coresubnet"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = local.hub_subnets.coresubnet
}

resource "azurerm_route_table" "core" {
  name                          = "rt_hub_coresubnet"
  location                      = azurerm_resource_group.network.location
  resource_group_name           = azurerm_resource_group.network.name
  disable_bgp_route_propagation = false

  route {
    name           = "internet"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.firewall.ip_configuration[0].private_ip_address
  }
  lifecycle {
    ignore_changes = [ route, tags ]
  }
}
resource "azurerm_subnet_route_table_association" "hub_core" {
  subnet_id      = azurerm_subnet.core.id
  route_table_id = azurerm_route_table.core.id
}

################ CDP VNET #############
resource "azurerm_virtual_network" "cdp" {
  name                = var.cdp_vnet_name
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
  address_space       = [var.cdp_cidr]
  tags                = var.tags
}
resource "azurerm_subnet" "cdp_subnets" {
  for_each             = local.cdp_subnets
  name                 = each.key
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.cdp.name
  address_prefixes     = [each.value]
  service_endpoints    = ["Microsoft.Sql", "Microsoft.Storage", "Microsoft.KeyVault"]
}
resource "azurerm_subnet" "dns_resolver_inbound" {
  name                 = "dns_resolver_inbound"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.cdp.name
  address_prefixes     = [local.resolver_inbound_subnet_cidr]

  delegation {
    name = "Microsoft.Network.dnsResolvers"
    service_delegation {
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      name    = "Microsoft.Network/dnsResolvers"
    }
  }
}
resource "azurerm_subnet" "pg_flx" {
  name                 = "pg_flexible_subnet"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.cdp.name
  address_prefixes     = [local.pg_flx_subnet_cidr]
  service_endpoints    = ["Microsoft.Storage"]
  delegation {
    name = "Microsoft.DBforPostgreSQL/flexibleServers"
    service_delegation {
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"] 
          # this is a default action. If not added, Azure will add it by default, and next terraform apply will try to remove it. Lifecycling it is not appropriate.
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
    }
  }
}
########### Peering ##############
resource "azurerm_virtual_network_peering" "hub_cdp" {
  name                      = "hub_cdp"
  resource_group_name       = azurerm_resource_group.network.name
  virtual_network_name      = azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.cdp.id
}

resource "azurerm_virtual_network_peering" "cdp_hub" {
  name                      = "cdp_hub"
  resource_group_name       = azurerm_resource_group.network.name
  virtual_network_name      = azurerm_virtual_network.cdp.name
  remote_virtual_network_id = azurerm_virtual_network.hub.id
}


############# Route tables ##############
resource "azurerm_route_table" "cdp_route" {
  for_each                      = local.cdp_subnets
  name                          = "rt_cdp_${each.key}"
  location                      = azurerm_resource_group.network.location
  resource_group_name           = azurerm_resource_group.network.name
  disable_bgp_route_propagation = false

  route {
    name           = "internet"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.firewall.ip_configuration[0].private_ip_address
  }
  lifecycle {
    ignore_changes = [ route, tags ]
  }
}

resource "azurerm_subnet_route_table_association" "cdp_rt_associate" {
  for_each       = azurerm_subnet.cdp_subnets
  subnet_id      = azurerm_subnet.cdp_subnets[each.key].id
  route_table_id = azurerm_route_table.cdp_route[each.key].id
}

############# Private DNS Zone ############
resource "azurerm_private_dns_zone" "aks" {
  name                = "privatelink.${var.location}.azmk8s.io"
  resource_group_name = azurerm_resource_group.network.name
  tags                = var.tags
}
resource "azurerm_private_dns_zone_virtual_network_link" "cdp_aks" {
  name                  = "cdp_vnet"
  resource_group_name   = azurerm_resource_group.network.name
  private_dns_zone_name = azurerm_private_dns_zone.aks.name
  virtual_network_id    = azurerm_virtual_network.cdp.id
}

resource "azurerm_private_dns_zone" "pg_flx" {
  name                = "${var.location}.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.network.name
  tags                = var.tags
}
resource "azurerm_private_dns_zone_virtual_network_link" "pg_flx" {
  name                  = "cdp_vnet"
  resource_group_name   = azurerm_resource_group.network.name
  private_dns_zone_name = azurerm_private_dns_zone.pg_flx.name
  virtual_network_id    = azurerm_virtual_network.cdp.id
}
resource "azurerm_private_dns_zone" "storage" {
  name                = "privatelink.dfs.core.windows.net"
  resource_group_name = azurerm_resource_group.network.name
  tags                = var.tags
}
resource "azurerm_private_dns_zone_virtual_network_link" "storage" {
  name                  = "hub_vnet"
  resource_group_name   = azurerm_resource_group.network.name
  private_dns_zone_name = azurerm_private_dns_zone.storage.name
  virtual_network_id    = azurerm_virtual_network.hub.id
}
output "private_dns_zones" {
  value = {
    aksPrivateDNSZoneID      = azurerm_private_dns_zone.aks.id
    postgresPrivateDNSZoneID = azurerm_private_dns_zone.pg_flx.id
  }
}
########## Private DNS Resolver ##############
resource "azurerm_private_dns_resolver" "dns_resolver" {
  name                = var.dns_resolver_name
  resource_group_name = azurerm_resource_group.network.name
  location            = azurerm_resource_group.network.location
  virtual_network_id  = azurerm_virtual_network.cdp.id
  tags                = var.tags
}
resource "azurerm_private_dns_resolver_inbound_endpoint" "inbound" {
  // After this enndpoint is created, use this ip address for the DNS conditional forward for all Azure private link domains.
  name                    = "inbound"
  private_dns_resolver_id = azurerm_private_dns_resolver.dns_resolver.id
  location                = azurerm_private_dns_resolver.dns_resolver.location
  ip_configurations {
    private_ip_allocation_method = "Dynamic"
    subnet_id                    = azurerm_subnet.dns_resolver_inbound.id
  }
  tags = var.tags
}
output "dns_resolver_inbound_ip" {
  value = azurerm_private_dns_resolver_inbound_endpoint.inbound.ip_configurations[0].private_ip_address
}

############### VNET DNS Configuration ###########
resource "azurerm_virtual_network_dns_servers" "hub" {
  count              = var.custom_dns ? 1:0
  virtual_network_id = azurerm_virtual_network.hub.id
  dns_servers        = [azurerm_linux_virtual_machine.hub-jump.private_ip_address]
}

resource "azurerm_virtual_network_dns_servers" "cdp" {
  count              = var.custom_dns ? 1:0
  virtual_network_id = azurerm_virtual_network.cdp.id
  dns_servers        = [azurerm_linux_virtual_machine.hub-jump.private_ip_address]
}