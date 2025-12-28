############### Resource group ################
resource "azurerm_resource_group" "vm" {
  count    = var.create_resource_group ? 1:0
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}
data "azurerm_resource_group" "vm" {
  count    = var.create_resource_group ? 0:1
  name     = var.resource_group_name
}
locals {
  resource_group_name = var.create_resource_group ? azurerm_resource_group.vm[0].name : data.azurerm_resource_group.vm[0].name
}

############ virtual machine ##############
resource "azurerm_public_ip" "vm" {
  count               = var.create_public_ip ? 1:0
  name                = "${var.vm_name}-pip"
  resource_group_name = local.resource_group_name
  location            = var.location
  allocation_method   = "Static"

  tags = var.tags
}

resource "azurerm_network_security_group" "vm" {
  count               = var.use_nsg ? 1:0
  name                = "${var.vm_name}-sg"
  location            = var.location
  resource_group_name = local.resource_group_name

  security_rule {
    name                       = "AllowAll"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

resource "azurerm_network_interface" "vm" {
  name                = "${var.vm_name}-nic"
  location            = var.location
  resource_group_name = local.resource_group_name

  ip_configuration {
    name                          = "ip1"
    subnet_id                     = var.vm_subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.create_public_ip ? azurerm_public_ip.vm[0].id : null
  }
  tags = var.tags
}

resource "azurerm_network_interface_security_group_association" "vm" {
  count                     = var.use_nsg ? 1:0
  network_interface_id      = azurerm_network_interface.vm.id
  network_security_group_id = azurerm_network_security_group.vm[0].id
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = var.vm_name
  resource_group_name = local.resource_group_name
  location            = var.location
  size                = var.vm_size
  admin_username      = var.admin_username

  disable_password_authentication = true
  network_interface_ids = [
    azurerm_network_interface.vm.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_pub_key)
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

  user_data   = var.user_data == null ? null : base64encode(var.user_data)

  tags = var.tags

}
output "public_ip" {
  value = var.create_public_ip? azurerm_public_ip.vm[0].ip_address : null
}
output "private_ip" {
  value = azurerm_network_interface.vm.private_ip_address
}
