## configuration in the SPOKE VNET. Private DNS Resolver and endpoints.

locals {
  break_down                     = split("/", var.spoke_vnet_id)
  spoke_vnet_resource_group_name = local.break_down[4]
  spoke_vnet_name                = local.break_down[8]
}
resource "azurerm_subnet" "dns_resolver_inbound" {
  resource_group_name  = local.spoke_vnet_resource_group_name
  virtual_network_name = local.spoke_vnet_name
  name                 = "dns_resolver_inbound"
  address_prefixes     = [ var.dns_resolver_subnet_prefix ]
  service_endpoints    = ["Microsoft.Sql", "Microsoft.Storage", "Microsoft.KeyVault"]
  delegation {
    name = "Microsoft.Network/dnsResolvers"
    service_delegation {
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"] 
          # this is a default action. If not added, Azure will add it by default, and next terraform apply will try to remove it. Lifecycling it is not appropriate.
      name    = "Microsoft.Network/dnsResolvers"
    }
  }
}
resource "azurerm_private_dns_resolver" "dns_resolver" {
  name                = var.private_dns_resolver_name == "" ? "dns-resolver" : var.private_dns_resolver_name
  resource_group_name = local.spoke_vnet_resource_group_name
  location            = var.location
  virtual_network_id  = var.spoke_vnet_id
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


############# SPOKE VNET DNS setting ###########
resource "azurerm_virtual_network_dns_servers" "spoke" {
  count              = var.spoke_vnet_default_dns ? 0:1
  virtual_network_id = var.spoke_vnet_id
  dns_servers        = [module.dns_server.private_ip]
}