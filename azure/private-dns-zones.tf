module "dns_zone" {
  source               = "./modules/az-private_dns_zones"
  subscription_id      = "abce3e07-b32d-4b41-8c78-2bcaffe4ea27"
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
