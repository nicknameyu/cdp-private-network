##### This is to create DNS server as well as hub-spoke DNS setup on the hub-spoke VNET
module "hub_spoke_dns" {
  source                     = "./modules/az-hub_spoke-dns"
  hub_vnet_default_dns       = true
  spoke_vnet_id              = module.spoke_vnet.vnet_id
  dns_resolver_subnet_prefix = cidrsubnet(var.cdp_cidr, 12, 1)
  private_dns_resolver_name  = "${var.owner}-dns-resolver"

  dns_server_resource_group_name   = var.resource_groups != null ? var.resource_groups.vms_rg : "${var.owner}-vms"
  create_dns_server_resource_group = true
  location                         = var.location
  dns_server_name                  = "dns-server"
  dns_server_subnet_id             = module.hub_vnet.std_subnet_ids["pub_subnet_1"]
  admin_username                   = var.admin_username == null ? var.owner : var.admin_username
  conditional_forward_zones = {
    aks   = element(split("/", module.dns_zone.private_dns_zones.aks), length(split("/", module.dns_zone.private_dns_zones.aks)) - 1)
    pgdb  = element(split("/", module.dns_zone.private_dns_zones.pgdb), length(split("/", module.dns_zone.private_dns_zones.pgdb)) - 1)
    mysql = element(split("/", module.dns_zone.private_dns_zones.mysql), length(split("/", module.dns_zone.private_dns_zones.mysql)) - 1)
  }
  ssh_pub_key                      = var.public_key
  ssh_private_key                  = var.private_key
  tags                             = var.tags
}

output "dns-server_pip" {
  value = module.hub_spoke_dns.dns-server_ip
}


###### Create a jump server on CDP VNNET
module "cdp_jump_server" {
  source                = "./modules/az-ubuntu_vm"
  resource_group_name   = var.resource_groups != null ? var.resource_groups.vms_rg : "${var.owner}-vms"
  create_resource_group = false
  location              = var.location
  vm_subnet_id          = module.spoke_vnet.std_subnet_ids["pvt_subnet_1"]
  vm_name               = "cdp-jump-server"
  admin_username        = var.admin_username == null ? var.owner : var.admin_username
  create_public_ip      = false
  ssh_pub_key           = var.public_key
  ssh_private_key       = var.private_key
  depends_on            = [ module.hub_spoke_dns  ]
}
output "cdp-server_ip" {
  value = module.cdp_jump_server.private_ip
}

###### Create a Windows VM on the HUB VNET 
module "Windows" {
  count                 = var.create_win_client ? 1:0
  source                = "./modules/az-win11"
  resource_group_name   = var.resource_groups != null ? var.resource_groups.vms_rg : "${var.owner}-vms"
  create_resource_group = false
  location              = var.location
  vm_subnet_id          = module.hub_vnet.std_subnet_ids["pub_subnet_1"]
  vm_name               = "win-jump-server"
  admin_username        = var.admin_username == null ? var.owner : var.admin_username
  admin_user_password   = "Passw0rd"
  create_public_ip      = true
  use_nsg               = true
  depends_on            = [ module.hub_spoke_dns  ]
}
output "win-server_ip" {
  value = var.create_win_client ? module.Windows[0].public_ip : null
}