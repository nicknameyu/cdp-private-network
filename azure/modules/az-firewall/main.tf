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


################ Firewall #############
resource "azurerm_public_ip" "firewall" {
  name                = "pip_firewall"
  resource_group_name = local.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = var.tags
}

resource "azurerm_firewall" "firewall" {
  name                = var.firewall_name
  location            = var.location
  resource_group_name = local.resource_group_name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  tags                = var.tags

  ip_configuration {
    name                 = "configuration"
    subnet_id            = var.firewall_subnet_id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }
}

output "firewapp_internal_ip" {
  value = azurerm_firewall.firewall.ip_configuration[0].private_ip_address
}

######## Associate NVA endpoint to private network route table #############
data "azurerm_subnet" "source" {
  for_each             = var.subnets
  name                 = each.key
  resource_group_name  = split("/", each.value)[4]
  virtual_network_name = split("/", each.value)[8]
}

resource "azurerm_route" "internet" {
  for_each               = data.azurerm_subnet.source
  name                   = "internet"
  resource_group_name    = split("/", each.value.id)[4]
  route_table_name       = split("/", each.value.route_table_id)[8]
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.firewall.ip_configuration[0].private_ip_address
}

############### Firewall Rules ###################
resource "azurerm_firewall_application_rule_collection" "app_rules" {
  name                = "cdp-app-collection"
  azure_firewall_name = azurerm_firewall.firewall.name
  resource_group_name = local.resource_group_name
  priority            = 120
  action              = "Allow"

  dynamic "rule" {
    for_each = var.fw_app_rules 
    content {
      name = rule.key
      source_addresses = var.egress_source_cidrs
      target_fqdns     = rule.value.target_fqdns
      protocol {
        port = rule.value.port
        type = rule.value.type
      }
    }
  }
}

resource "azurerm_firewall_network_rule_collection" "network_rules" {
  name                = "cdp-network-collection"
  azure_firewall_name = azurerm_firewall.firewall.name
  resource_group_name = local.resource_group_name
  priority            = 130
  action              = "Allow"
  dynamic "rule" {
    for_each = var.fw_net_rules 
    content {
      name                  = rule.key
      source_addresses      = var.egress_source_cidrs
      destination_ports     = rule.value.destination_ports
      destination_addresses = rule.value.ip_prefix
      protocols             = rule.value.protocols
    }
  }
}
