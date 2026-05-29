module "cmk-prerequisite" {
  source                     = "github.com/nicknameyu/cdp-prerequisite-module/azure/cmk-prerequisites"
  resource_group_name        = module.env-prerequisite.storage_account.resource_group_name
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

# Storage account encryption
resource "azurerm_storage_account_customer_managed_key" "cdp" {
  for_each                  = var.kv_name == "" ? {} : {
                                                          cdp = module.env-prerequisite.storage_account.storage_account_id
                                                          nfs = module.env-prerequisite.nfs_storage.storage_account_id
                                                        }
  storage_account_id        = each.value
  key_vault_key_id          = module.cmk-prerequisite.cmk_key_id
  user_assigned_identity_id = module.env-prerequisite.mi_ids.cmk_ds
  depends_on                = [ module.service_principal ]
}
