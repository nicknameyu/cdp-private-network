################ Firewall #############
resource "azurerm_public_ip" "firewall" {
  name                = "pip_firewall"
  resource_group_name = azurerm_resource_group.network.name
  location            = azurerm_resource_group.network.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = var.tags
}

resource "azurerm_firewall" "firewall" {
  name                = var.firewall_name
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  tags                = var.tags

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }
  ip_configuration {
    name                 = "dns"
    #subnet_id            = azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.dns.id
  }
  ip_configuration {
    name                 = "jump"
    #subnet_id            = azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.hub-jump.id
  }
}


resource "azurerm_firewall_application_rule_collection" "app_rules" {
  name                = "cdp-app-collection"
  azure_firewall_name = azurerm_firewall.firewall.name
  resource_group_name = azurerm_resource_group.network.name
  priority            = 120
  action              = "Allow"

  dynamic "rule" {
    for_each = var.fw_app_rules 
    content {
      name = rule.key
      source_addresses = ["10.0.0.0/8"]
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
  resource_group_name = azurerm_resource_group.network.name
  priority            = 130
  action              = "Allow"
  dynamic "rule" {
    for_each = var.fw_net_rules 
    content {
      name = rule.key
      source_addresses = ["10.0.0.0/8"]
      destination_ports     = rule.value.destination_ports
      destination_addresses = rule.value.ip_prefix
      protocols             = rule.value.protocols
    }
  }
}