module "service_principal" {
  source               = "github.com/nicknameyu/cdp-prerequisite-module/azure/service-principal"
  subscription_id      = var.subscription_id
  tenant_id            = var.tenant_id

  spn_object_id        = var.spn_object_id
  create_spn           = false
  
  custom_role_name     = "${var.owner} CDP Custom role"
  create_custom_role   = ! var.spn_permision_contributor
  enable_cmk_rbac      = var.kv_rbac
  enable_dw            = var.enable_dw
  enable_liftie        = var.enable_liftie
  enable_de            = var.enable_de
}

module "managed_identity_rbac" {
  source               = "github.com/nicknameyu/cdp-prerequisite-module/azure/managed-identity-rbac"
  subscription_id      = var.subscription_id
  custom_role_name     = "${var.owner} CDP MI role"
  create_custom_role   = true
  mi_principal_id      = module.env-prerequisite.mi_principal_ids.dataaccess
  enable_cmk_rbac      = var.kv_rbac
  enable_dw            = var.enable_dw
  enable_liftie        = var.enable_liftie
}

module "dns-zone-role-assignment" {
  count            = var.dns_zone_subscription_id != null && var.dns_zone_subscription_id != var.subscription_id ? 1:0
  source           = "github.com/nicknameyu/cdp-prerequisite-module/azure/dns-zone-role-assignment"
  providers        = {
    azurerm.dns_zone = azurerm.secondary
  }
  principal_ids    = {
    spn = var.spn_object_id
    mi  = module.env-prerequisite.mi_principal_ids.dataaccess
  }
}
