resource "azurerm_resource_group" "vm" {
  name     = var.resource_groups != null ? var.resource_groups.vms_rg : "${var.owner}-vms"
  location = var.location
  tags     = var.tags
}

locals {
  admin_username = var.admin_username == null ? var.owner : var.admin_username
}

############ Hub Jump Server / DNS server ##############
resource "azurerm_network_interface" "hub-jump" {
  name                = var.hub_jump_server_name == null ? "${var.owner}HubJump-nic" : "${var.hub_jump_server_name}-nic"
  location            = azurerm_resource_group.vm.location
  resource_group_name = azurerm_resource_group.vm.name

  ip_configuration {
    name                          = "ip1"
    subnet_id                     = azurerm_subnet.core.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = var.tags
}
locals {
  dns_conditional_forwarder = replace(
                                replace(
                                  replace(file("./conf/named.conf"), "$${AKS_PRIVATEDNS_ZONE}", "${azurerm_private_dns_zone.aks.name}"),
                                  "$${PG_PRIVATEDNS_ZONE}", "${azurerm_private_dns_zone.pg_flx.name}"
                                ),
                                "$${DNS_RESOLVER_IP}", "${azurerm_private_dns_resolver_inbound_endpoint.inbound.ip_configurations[0].private_ip_address}"
                              )
}
resource "azurerm_linux_virtual_machine" "hub-jump" {
  name                = var.hub_jump_server_name == null ? "${var.owner}HubJump" : var.hub_jump_server_name
  resource_group_name = azurerm_resource_group.vm.name
  location            = azurerm_resource_group.vm.location
  size                = "Standard_DS1_v2"
  admin_username      = local.admin_username
  depends_on          = [ azurerm_firewall_nat_rule_collection.dnat, 
                          azurerm_firewall_application_rule_collection.app_rules, 
                          azurerm_firewall_network_rule_collection.network_rules,
                          azurerm_firewall_network_rule_collection.public_subnet
                          ]

  disable_password_authentication = true
  network_interface_ids = [
    azurerm_network_interface.hub-jump.id,
  ]

  admin_ssh_key {
    username   = local.admin_username
    public_key = file(var.public_key)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  tags = var.tags

  #######  setup DNS server ########
  connection {
    type        = "ssh"
    user        = local.admin_username
    private_key = file(var.private_key)
    host        = azurerm_public_ip.hub-jump.ip_address
  }
  provisioner "file" {
    source      = var.private_key
    destination = "/home/${local.admin_username}/.ssh/id_rsa"
  }
  provisioner "file" {
    content = local.dns_conditional_forwarder
    destination = "/tmp/named.conf"
  }
  provisioner "file" {
    source      = "conf/named.conf.options"
    destination = "/tmp/named.conf.options"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt install bind9 -y",
      "sudo apt install dnsutils -y",
      "cat /tmp/named.conf | sudo tee -a /etc/bind/named.conf",
      "sudo mv /etc/bind/named.conf.options /etc/bind/named.conf.options.backup",
      "sudo mv /tmp/named.conf.options /etc/bind/named.conf.options",
      "sudo chown root:bind /etc/bind/named.conf.options",
      "sudo chmod 644 /etc/bind/named.conf.options",
      "chmod 600 /home/${local.admin_username}/.ssh/id_rsa",
      "sudo systemctl restart bind9.service"
    ]
  }
}

###############   CDP VNET Jump Server ################
resource "azurerm_network_interface" "cdp-jump" {
  name                = var.cdp_jump_server_name == null ? "${var.owner}CdpJump-nic" : "${var.cdp_jump_server_name}-nic"
  location            = azurerm_resource_group.vm.location
  resource_group_name = azurerm_resource_group.vm.name

  ip_configuration {
    name                          = "ip1"
    subnet_id                     = azurerm_subnet.cdp_subnets["subnet_26_1"].id
    private_ip_address_allocation = "Dynamic"
  }
  tags = var.tags
}
resource "azurerm_linux_virtual_machine" "cdp-jump" {
  name                = var.cdp_jump_server_name == null ? "${var.owner}CdpJump" : var.cdp_jump_server_name
  resource_group_name = azurerm_resource_group.vm.name
  location            = azurerm_resource_group.vm.location
  size                = "Standard_DS1_v2"
  admin_username      = local.admin_username
  disable_password_authentication = true
  network_interface_ids = [
    azurerm_network_interface.cdp-jump.id,
  ]

  admin_ssh_key {
    username   = local.admin_username
    public_key = file(var.public_key)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  tags = var.tags
}

output "cdp_jump_server_private_ip" {
  value = azurerm_network_interface.cdp-jump.ip_configuration[0].private_ip_address
}

############# DNS Server ##################
resource "azurerm_network_interface" "win11" {
  name                = var.winclient_vm_name == null ? "${var.owner}WinClient-nic":"${var.winclient_vm_name}-nic"
  location            = azurerm_resource_group.vm.location
  resource_group_name = azurerm_resource_group.vm.name

  ip_configuration {
    name                          = "ip1"
    subnet_id                     = azurerm_subnet.core.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = var.tags
}
resource "azurerm_windows_virtual_machine" "win11" {
  name                = var.winclient_vm_name == null ? "${var.owner}WinClient" : var.winclient_vm_name
  resource_group_name = azurerm_resource_group.vm.name
  location            = azurerm_resource_group.vm.location
  size                = "Standard_DS1_v2"
  admin_username      = local.admin_username
  admin_password      = var.password
  network_interface_ids = [
    azurerm_network_interface.win11.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "windows-11"
    sku       = "win11-23h2-pro"
    version   = "latest"
  }
  tags = var.tags
}

################ DNAT Setting ###############
resource "azurerm_public_ip" "win11" {
  name                = "pip_win11"
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
    translated_address = azurerm_network_interface.hub-jump.private_ip_address
    protocols = ["TCP","UDP",]
  }
  rule {
    name = "win11"
    source_addresses = ["*"]
    destination_ports = ["3389",]
    destination_addresses = [azurerm_public_ip.win11.ip_address]
    translated_port = 3389
    translated_address = azurerm_network_interface.win11.private_ip_address
    protocols = ["TCP","UDP",]
  }
}

output "winclient_vm_public_ip" {
  value = azurerm_public_ip.win11.ip_address
}
output "hub_jump_server_public_ip" {
  value = azurerm_public_ip.hub-jump.ip_address
}