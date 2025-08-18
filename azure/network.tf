############### Hub VNET #############
resource "azurerm_resource_group" "network" {
  name     = var.resource_groups != null ? var.resource_groups.network_rg : "${var.owner}-network"
  location = var.location
  tags = var.tags
}
resource "azurerm_virtual_network" "hub" {
  name                = var.hub_vnet_name == null ? "${var.owner}-hub-vnet" : var.hub_vnet_name
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
  default_outbound_access_enabled = false
}

resource "azurerm_subnet" "core" {
  name                 = "coresubnet"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = local.hub_subnets.coresubnet
  default_outbound_access_enabled = var.public_env ? true : false
}

resource "azurerm_route_table" "core" {
  name                          = "rt_hub_coresubnet"
  location                      = azurerm_resource_group.network.location
  resource_group_name           = azurerm_resource_group.network.name
  bgp_route_propagation_enabled = false

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


resource "azurerm_subnet" "pub" {
  for_each             = local.hub_pub_subnets
  name                 = each.key
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = each.value
  service_endpoints    = ["Microsoft.Sql", "Microsoft.Storage", "Microsoft.KeyVault"]
}
resource "azurerm_route_table" "pub" {
  for_each                      = local.hub_pub_subnets
  name                          = "rt_${each.key}"
  location                      = azurerm_resource_group.network.location
  resource_group_name           = azurerm_resource_group.network.name
  bgp_route_propagation_enabled = false

  lifecycle {
    ignore_changes = [ route, tags ]
  }
}
resource "azurerm_subnet_route_table_association" "pub" {
  for_each       = azurerm_subnet.pub
  subnet_id      = azurerm_subnet.pub[each.key].id
  route_table_id = azurerm_route_table.pub[each.key].id
}

################ CDP VNET #############
resource "azurerm_virtual_network" "cdp" {
  name                = var.cdp_vnet_name == null ? "${var.owner}-cdp-vnet" : var.cdp_vnet_name
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
  default_outbound_access_enabled = var.public_env ? true : false
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
resource "azurerm_route_table" "cdp_route_pvt" {
  for_each                      = var.public_env ? {} : local.cdp_subnets
  name                          = "rt_cdp_${each.key}"
  location                      = azurerm_resource_group.network.location
  resource_group_name           = azurerm_resource_group.network.name
  bgp_route_propagation_enabled = false

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

resource "azurerm_route_table" "cdp_route_pub" {
  for_each                      = var.public_env ? local.cdp_subnets : {}
  name                          = "rt_cdp_pub_${each.key}"
  location                      = azurerm_resource_group.network.location
  resource_group_name           = azurerm_resource_group.network.name
  bgp_route_propagation_enabled = false

  lifecycle {
    ignore_changes = [ route, tags ]
  }
}


resource "azurerm_subnet_route_table_association" "cdp_rt_associate" {
  for_each       = azurerm_subnet.cdp_subnets
  subnet_id      = azurerm_subnet.cdp_subnets[each.key].id
  route_table_id = var.public_env ? azurerm_route_table.cdp_route_pub[each.key].id : azurerm_route_table.cdp_route_pvt[each.key].id
}

########## Private DNS Resolver ##############
resource "azurerm_private_dns_resolver" "dns_resolver" {
  name                = var.dns_resolver_name == null ? "${var.owner}-dns-resolver" : var.dns_resolver_name
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