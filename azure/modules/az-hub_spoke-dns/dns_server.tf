module "dns_server" {
  source                = "../az-ubuntu_vm"
  resource_group_name   = var.dns_server_resource_group_name
  create_resource_group = var.create_dns_server_resource_group
  location              = var.location
  vm_subnet_id          = var.dns_server_subnet_id
  vm_name               = var.dns_server_name
  admin_username        = var.admin_username
  create_public_ip      = true
  user_data             = file("${path.module}/scripts/dns_vm_user_data.sh")
  use_nsg               = true
}
output "dns-server_ip" {
  value = {
    public = module.dns_server.public_ip
    private = module.dns_server.private_ip
  }
}

############# DNS Server Bootstrapping ############
resource "null_resource" "private_key" {
  triggers = {
    name = sha1(file(var.ssh_private_key))
  }
  connection {
    type        = "ssh"
    user        = var.admin_username
    private_key = file(var.ssh_private_key)
    host        = module.dns_server.public_ip
  }
  provisioner "file" {
    content = file(var.ssh_private_key)
    destination = "/tmp/id_rsa"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo rm /home/${var.admin_username}/.ssh/id_rsa",
      "sudo mv /tmp/id_rsa /home/${var.admin_username}/.ssh/id_rsa",
      "sudo chmod 600 /home/${var.admin_username}/.ssh/id_rsa"
    ]
  }
}

locals {
  named_conf         = templatefile("${path.module}/conf/named.conf", {
    aks_private_dns_zone    = var.conditional_forward_zones.aks
    pg_private_dns_zone     = var.conditional_forward_zones.pgdb
    mysql_private_dns_zone  = var.conditional_forward_zones.mysql
    dns_resolver_ip         = azurerm_private_dns_resolver_inbound_endpoint.inbound.ip_configurations[0].private_ip_address
  })
  named_conf_options = file("${path.module}/conf/named.conf.options")
}

resource "null_resource" "conf" {
  triggers = {
    name = "${sha1(local.named_conf)} + ${sha1(local.named_conf_options)} + ${sha1(file("${path.module}/scripts/bootstrap.sh"))}"
  }
  connection {
    type        = "ssh"
    user        = var.admin_username
    private_key = file(var.ssh_private_key)
    host        = module.dns_server.public_ip
  }
  provisioner "file" {
    content = local.named_conf
    destination = "/tmp/named.conf"
  }
  provisioner "file" {
    content = local.named_conf_options
    destination = "/tmp/named.conf.options"
  }

  provisioner "file" {
    source = "${path.module}/scripts/bootstrap.sh"
    destination = "/tmp/bootstrap.sh"
  }
  provisioner "remote-exec" {
    inline = [ 
      "sudo bash /tmp/bootstrap.sh >> /tmp/bootstrap.log 2>&1"
    ]
  }
  depends_on = [ module.dns_server ]
}
