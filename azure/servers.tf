resource "azurerm_resource_group" "vm" {
  name     = var.resource_groups.vms_rg
  location = var.location
  tags     = var.tags
}

resource "azurerm_network_interface" "hub-jump" {
  name                = "${var.hub_jump_server_name}-nic"
  location            = azurerm_resource_group.vm.location
  resource_group_name = azurerm_resource_group.vm.name

  ip_configuration {
    name                          = "ip1"
    subnet_id                     = azurerm_subnet.core.id
    private_ip_address_allocation = "Dynamic"
  }
}
resource "azurerm_linux_virtual_machine" "hub-jump" {
  name                = "${var.hub_jump_server_name}-vm"
  resource_group_name = azurerm_resource_group.vm.name
  location            = azurerm_resource_group.vm.location
  size                = "Standard_DS1_v2"
  admin_username      = var.admin_username
  disable_password_authentication = true
  network_interface_ids = [
    azurerm_network_interface.hub-jump.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.public_key)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }
}


resource "azurerm_network_interface" "cdp-jump" {
  name                = "${var.cdp_jump_server_name}-nic"
  location            = azurerm_resource_group.vm.location
  resource_group_name = azurerm_resource_group.vm.name

  ip_configuration {
    name                          = "ip1"
    subnet_id                     = azurerm_subnet.cdp_subnets["subnet_26_1"].id
    private_ip_address_allocation = "Dynamic"
  }
}
resource "azurerm_linux_virtual_machine" "cdp-jump" {
  name                = "${var.cdp_jump_server_name}-vm"
  resource_group_name = azurerm_resource_group.vm.name
  location            = azurerm_resource_group.vm.location
  size                = "Standard_DS1_v2"
  admin_username      = var.admin_username
  disable_password_authentication = true
  network_interface_ids = [
    azurerm_network_interface.cdp-jump.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.public_key)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }
}

output "cdp_jump_server_private_ip" {
  value = azurerm_network_interface.cdp-jump.ip_configuration[0].private_ip_address
}

############# DNS Server ##################
resource "azurerm_network_interface" "dns" {
  name                = "${var.dns_server_name}-nic"
  location            = azurerm_resource_group.vm.location
  resource_group_name = azurerm_resource_group.vm.name

  ip_configuration {
    name                          = "ip1"
    subnet_id                     = azurerm_subnet.core.id
    private_ip_address_allocation = "Dynamic"
  }
}
resource "azurerm_windows_virtual_machine" "dns" {
  name                = "${var.dns_server_name}-vm"
  resource_group_name = azurerm_resource_group.vm.name
  location            = azurerm_resource_group.vm.location
  size                = "Standard_DS1_v2"
  admin_username      = var.admin_username
  admin_password      = var.password
  network_interface_ids = [
    azurerm_network_interface.dns.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_virtual_network_dns_servers" "hub" {
  count              = var.custom_dns ? 1:0
  virtual_network_id = azurerm_virtual_network.hub.id
  dns_servers        = [azurerm_windows_virtual_machine.dns.private_ip_address]
}

resource "azurerm_virtual_network_dns_servers" "cdp" {
  count              = var.custom_dns ? 1:0
  virtual_network_id = azurerm_virtual_network.cdp.id
  dns_servers        = [azurerm_windows_virtual_machine.dns.private_ip_address]
}

################ DNAT Setting ###############
resource "azurerm_public_ip" "dns" {
  name                = "pip_dns"
  resource_group_name = azurerm_resource_group.vm.name
  location            = azurerm_resource_group.vm.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = var.tags
}

resource "azurerm_public_ip" "hub-jump" {
  name                = "pip_jump"
  resource_group_name = azurerm_resource_group.vm.name
  location            = azurerm_resource_group.vm.location
  allocation_method   = "Static"
  tags                = var.tags
  sku                 = "Standard"

}
resource "azurerm_firewall_nat_rule_collection" "dnat" {
  name                = "jump-servers"
  azure_firewall_name = azurerm_firewall.firewall.name
  resource_group_name = azurerm_resource_group.network.name
  priority            = 110
  action              = "Dnat"

  rule {
    name = "hub-jump"
    source_addresses = ["*"]
    destination_ports = ["22",]
    destination_addresses = [azurerm_public_ip.hub-jump.ip_address]
    translated_port = 22
    translated_address = azurerm_linux_virtual_machine.hub-jump.private_ip_address
    protocols = ["TCP","UDP",]
  }
  rule {
    name = "dns"
    source_addresses = ["*"]
    destination_ports = ["3389",]
    destination_addresses = [azurerm_public_ip.dns.ip_address]
    translated_port = 3389
    translated_address = azurerm_windows_virtual_machine.dns.private_ip_address
    protocols = ["TCP","UDP",]
  }
}

output "dns_server_public_ip" {
  value = azurerm_public_ip.dns.ip_address
}
output "hub_jump_server_public_ip" {
  value = azurerm_public_ip.hub-jump.ip_address
}