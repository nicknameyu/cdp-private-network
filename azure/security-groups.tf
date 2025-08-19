############### CDP Security Group ####################
resource "azurerm_network_security_group" "default" {
  for_each            = {
                           default = "${var.owner}-nsg-default", 
                           knox    = "${var.owner}-nsg-knox"
                        }
  name                = each.key
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name

  security_rule {
    name                       = "ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = [var.cdp_cidr, var.hub_cidr]
    destination_address_prefix = var.cdp_cidr
  }
  security_rule {
    name                       = "https"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefixes    = [var.cdp_cidr, var.hub_cidr]
    destination_address_prefix = var.cdp_cidr
  }
  security_rule {
    name                       = "mgmt"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9443"
    source_address_prefixes    = [var.cdp_cidr, var.hub_cidr]
    destination_address_prefix = var.cdp_cidr
  }
  security_rule {
    name                       = "comm-tcp"
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "0-65535"
    source_address_prefix      = var.cdp_cidr
    destination_address_prefix = var.cdp_cidr
  }
  security_rule {
    name                       = "comm-udp"
    priority                   = 104
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "0-65535"
    source_address_prefix      = var.cdp_cidr
    destination_address_prefix = var.cdp_cidr
  }
  security_rule {
    name                       = "icmp"
    priority                   = 105
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = [var.cdp_cidr, var.hub_cidr]
    destination_address_prefix = var.cdp_cidr
  }
  tags = var.tags
}
