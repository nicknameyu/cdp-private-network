module "cmk-access-policy" {
  source                     = "github.com/nicknameyu/cdp-prerequisite-module/azure/cmk-prerequisites"
  resource_group_name        = module.env-prerequisite.storage_account.resource_group_name
  key_vault_name             = var.kv_name
  key_name                   = "cdp-key"
  subscription_id            = var.subscription_id
  location                   = var.location
  enable_access_policy       = false
  tags                       = var.tags
}

output "cmk_key_id" {
  value = var.kv_name != "" ? module.cmk-access-policy.cmk_key_id : ""
}