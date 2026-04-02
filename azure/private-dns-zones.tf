module "dns_zone" {
  source               = "./modules/az-private_dns_zones"
  subscription_id      = var.dns_zone_subscription_id
  resource_group_name  = "${var.owner}-dns-zone"
  location             = var.location
  vnet_ids = {
    hub   = module.hub_vnet.vnet_id
    spoke = module.spoke_vnet.vnet_id
  }
  tags                 = var.tags
}
output "private_dns_zones" {
  value = module.dns_zone.private_dns_zones
}
