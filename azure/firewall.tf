module "firewall" {
  source              = "./modules/az-firewall"
  resource_group_name = module.hub_vnet.resource_group_name
  firewall_name       = var.firewall_name == null ? "${var.owner}-fw" : var.firewall_name
  location            = var.location
  firewall_subnet_id  = module.hub_vnet.nva_subnet_ids.AzureFirewallSubnet
  egress_source_cidrs = [var.hub_cidr, var.cdp_cidr]
  subnets             = module.spoke_vnet.std_subnet_ids
  fw_app_rules        = var.fw_app_rules
  fw_net_rules        = var.fw_net_rules
  tags                = var.tags
}