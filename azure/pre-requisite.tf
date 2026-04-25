locals {
  resource_group_names = {
    prerequisite = var.resource_groups != null ? var.resource_groups.prerequisite_rg : "${var.owner}-cdp-prerequisite"
  }
}
module "env-prerequisite" {
  source = "github.com/nicknameyu/cdp-prerequisite-module/azure/env-prerequisites"
  subscription_id      = var.subscription_id
  managed_id           = {
                          assumer    = "${var.owner}-cdp-assumer"
                          dataaccess = "${var.owner}-cdp-dataaccess"
                          logger     = "${var.owner}-cdp-logger"
                          ranger     = "${var.owner}-cdp-ranger"
                          }
  storage_account_name = var.cdp_storage
  resource_group_name  = local.resource_group_names.prerequisite
  location             = var.location
  raz_mi_name          = "${var.owner}-cdp-raz"
  cmk_ds_mi_name       = "${var.owner}-cdp-cmk-ds"
  enable_de            = var.enable_de
  de_mi_names          = {
                            cluster1 = {
                              service = "${var.owner}-cdp-de-service"
                              cluster = "${var.owner}-cdp-de-cluster"
                            }
                            cluster2 = {
                              service = "${var.owner}-cdp-de-service2"
                              cluster = "${var.owner}-cdp-de-cluster2"
                            }
                          }
  subnet_ids           = concat(values(module.spoke_vnet.std_subnet_ids), values(module.hub_vnet.std_subnet_ids))
  obj_storage_performance = {
    account_tier = var.storage_account_tier
    replication  = var.storage_account_replication_type
  }
  enable_ai           = var.enable_ai
  create_nfs          = var.enable_ai || var.enable_de
  nfs_storage_account_name = var.cdp_file_storage

  tags                 = var.tags
}
output "managed_ids" {
  value = module.env-prerequisite.mi_ids
}


output "storage_locations" {
  value = {
    storage-location-base = module.env-prerequisite.storage_locations.storage_location_base
    log-location          = module.env-prerequisite.storage_locations.log_location
    backup-location       = module.env-prerequisite.storage_locations.backup_location
    nfs-file-share        = module.env-prerequisite.nfs_storage
  }
}

output "ssh_public_key" {
  value = file(var.public_key)
}