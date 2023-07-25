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
  address_space       = var.hub_cidr
  tags                = var.tags
}
resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = var.hub_subnets.AzureFirewallSubnet
}
resource "azurerm_subnet" "resolver" {
  name                 = "resolversubnet"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = var.hub_subnets.resolversubnet
}
resource "azurerm_subnet" "core" {
  name                 = "coresubnet"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = var.hub_subnets.coresubnet
}


################ CDP VNET #############
resource "azurerm_virtual_network" "cdp" {
  name                = var.cdp_vnet_name
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
  address_space       = var.cdp_cidr
  tags                = var.tags
}
resource "azurerm_subnet" "cdp_subnets" {
  for_each             = var.cdp_subnets
  name                 = each.key
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.cdp.name
  address_prefixes     = [each.value]
  service_endpoints    = ["Microsoft.Sql", "Microsoft.Storage"]
}
resource "azurerm_subnet" "dns_resolver_inbound" {
  name                 = "dns_resolver_inbound"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.cdp.name
  address_prefixes     = [var.resolver_inbound_subnet_cidr]

  delegation {
    name = "Microsoft.Network.dnsResolvers"
    service_delegation {
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      name    = "Microsoft.Network/dnsResolvers"
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
  for_each                      = var.cdp_subnets
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
# resource "azurerm_private_dns_zone_virtual_network_link" "hub_aks" {
#   name                  = "hub_vnet"
#   resource_group_name   = azurerm_resource_group.network.name
#   private_dns_zone_name = azurerm_private_dns_zone.aks.name
#   virtual_network_id    = azurerm_virtual_network.hub.id
# }

// this piece was to pre-create private DNS zone for mysql to be used in CDE, so that we can avoid creating private dns zone on the fly. 
// Turned out CDE anyway created private DNS zone on the fly.
# resource "azurerm_private_dns_zone" "mysql" {
#   name                = "privatelink.mysql.database.azure.com"
#   resource_group_name = azurerm_resource_group.network.name
#   tags                = var.tags
# }
# resource "azurerm_private_dns_zone_virtual_network_link" "cdp_db" {
#   name                  = "cdp_vnet"
#   resource_group_name   = azurerm_resource_group.network.name
#   private_dns_zone_name = azurerm_private_dns_zone.mysql.name
#   virtual_network_id    = azurerm_virtual_network.cdp.id
# }
# resource "azurerm_private_dns_zone_virtual_network_link" "hub_db" {
#   name                  = "hub_vnet"
#   resource_group_name   = azurerm_resource_group.network.name
#   private_dns_zone_name = azurerm_private_dns_zone.mysql.name
#   virtual_network_id    = azurerm_virtual_network.hub.id
# }

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