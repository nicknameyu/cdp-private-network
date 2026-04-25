module "cmk-prerequisite" {
  source                     = "github.com/nicknameyu/cdp-prerequisite-module/azure/cmk-prerequisites"
  resource_group_name        = module.env-prerequisite.storage_account.resource_group_name
  storage_account_ids        = { 
                                  cdp = module.env-prerequisite.storage_account.storage_account_id
                                  nfs =  module.env-prerequisite.nfs_storage.storage_account_id
                                }
  managed_identity_id        = module.env-prerequisite.mi_ids.cmk_ds
  key_vault_name             = var.kv_name
  key_name                   = "cdp-key"
  subscription_id            = var.subscription_id
  location                   = var.location
  enable_access_policy       = ! var.kv_rbac
  tags                       = var.tags
}

output "cmk_key_id" {
  value = var.kv_name != "" ? module.cmk-prerequisite.cmk_key_id : ""
}