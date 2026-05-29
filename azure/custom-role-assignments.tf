module "service_principal" {
  source               = "github.com/nicknameyu/cdp-prerequisite-module/azure/service-principal"
  # subscription_id      = var.subscription_id
  # tenant_id            = var.tenant_id

  spn_object_id        = var.spn_object_id
  create_spn           = false
  mi_object_id         = module.env-prerequisite.mi_principal_ids.cmk
  
  custom_role_name     = var.spn_permision_contributor ? null : "${var.owner} CDP Custom role"
  create_custom_role   = ! var.spn_permision_contributor


  scope                              =  {
                                          //sub          = "/subscriptions/${var.subscription_id}"
                                          prerequisite = module.env-prerequisite.prerequisite_resouorce_group_id
                                          cdp          = azurerm_resource_group.cdp.id
                                        }
  key_vault_id                       = var.kv_rbac ? module.cmk-prerequisite.cmk_key_vault_id : null

  vnet_resource_group_id             = module.hub_vnet.resource_group_id
  private_dns_zone_resource_group_id = module.dns_zone.resource_group_id

  enable_dw            = var.enable_dw
  enable_liftie        = var.enable_liftie
  enable_de            = var.enable_de
}

