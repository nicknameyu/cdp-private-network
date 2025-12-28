############### Resource group ################
resource "azurerm_resource_group" "network" {
  count    = var.create_resource_group ? 1:0
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

locals {
  resource_group_name = var.create_resource_group ? azurerm_resource_group.network[0].name : var.resource_group_name
}

############### VNET ################
resource "azurerm_virtual_network" "network" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = local.resource_group_name
  address_space       = [ var.cidr ]
  tags                = var.tags
}

############### Standard Subnets ################
resource "azurerm_subnet" "standard" {
  for_each             = var.std_subnets
  virtual_network_name = azurerm_virtual_network.network.name
  resource_group_name  = local.resource_group_name
  name                 = each.key
  address_prefixes     = [ each.value ]
  service_endpoints    = ["Microsoft.Sql", "Microsoft.Storage", "Microsoft.KeyVault"]
}

resource "azurerm_route_table" "standard" {
  for_each                      = var.std_subnets
  name                          = "rt_${each.key}"
  location                      = var.location
  resource_group_name           = local.resource_group_name
  bgp_route_propagation_enabled = false
  tags                          = var.tags
  lifecycle {
    ignore_changes = [ route, tags ]
  }
}
resource "azurerm_subnet_route_table_association" "standard" {
  for_each       = var.std_subnets
  subnet_id      = azurerm_subnet.standard[each.key].id
  route_table_id = azurerm_route_table.standard[each.key].id
}

############### Delegated Subnets ################
resource "azurerm_subnet" "svc_subnet" {
  for_each             = var.delegate_subnets
  name                 = each.key
  resource_group_name  = local.resource_group_name
  virtual_network_name = azurerm_virtual_network.network.name
  address_prefixes     = [ each.value.prefix ]
  service_endpoints    = ["Microsoft.Sql", "Microsoft.Storage", "Microsoft.KeyVault"]
  delegation {
    name = each.value.service
    service_delegation {
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"] 
          # this is a default action. If not added, Azure will add it by default, and next terraform apply will try to remove it. Lifecycling it is not appropriate.
      name    = each.value.service
    }
  }
}

############### Appliance Subnets ################
resource "azurerm_subnet" "nva_subnet" {
  for_each             = var.nva_subnets
  virtual_network_name = azurerm_virtual_network.network.name
  resource_group_name  = local.resource_group_name
  name                 = each.key
  address_prefixes     = [ each.value ]
  service_endpoints    = ["Microsoft.Sql", "Microsoft.Storage", "Microsoft.KeyVault"]
}

############### Output ################
output "resource_group_name" {
  value = local.resource_group_name
}

output "vnet_id" {
  value = azurerm_virtual_network.network.id
}
output "std_subnet_ids" {
  value = { for k, s in azurerm_subnet.standard : k => s.id }
}
output "std_route_table_names" {
  value = { for k, s in azurerm_route_table.standard : k => s.name }
}
output "delegate_subnet_ids" {
  value = { for k, s in azurerm_subnet.svc_subnet : k => s.id }
}
output "nva_subnet_ids" {
  value = { for k, s in azurerm_subnet.nva_subnet : k => s.id }
}