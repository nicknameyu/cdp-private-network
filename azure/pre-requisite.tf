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
  obj_storage_performance = {
    account_tier = var.storage_account_tier
    replication  = var.storage_account_replication_type
  }

  tags                 = var.tags
}

module "nfs-prerequisite" {
  source               = "github.com/nicknameyu/cdp-prerequisite-module/azure/nfs-prerequisites"
  subscription_id      = var.subscription_id
  resource_group_name  = module.env-prerequisite.storage_account.resource_group_name
  location             = var.location
  storage_account_name = var.cdp_file_storage
  file_share_name      = "cml-nfs"
  subnet_ids           = concat(
                                [ for k,v in module.hub_vnet.std_subnet_ids: v ],
                                [ for k,v in module.spoke_vnet.std_subnet_ids: v ],
                              )
  tags                 = var.tags
}

output "storage_locations" {
  value = {
    storage-location-base = module.env-prerequisite.storage_locations.storage_location_base
    log-location          = module.env-prerequisite.storage_locations.log_location
    backup-location       = module.env-prerequisite.storage_locations.backup_location
    nfs-file-share        = module.nfs-prerequisite.nfs_file_share
  }
}

output "ssh_public_key" {
  value = file(var.public_key)
}