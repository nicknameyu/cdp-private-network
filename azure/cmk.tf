resource "azurerm_key_vault" "kv" {
  count                      = var.kv_name != "" ? 1:0
  name                       = var.kv_name
  location                   = azurerm_resource_group.prerequisite.location
  resource_group_name        = azurerm_resource_group.prerequisite.name
  tenant_id                  = data.azurerm_subscription.current.tenant_id
  sku_name                   = "premium"
  soft_delete_retention_days = 7
  purge_protection_enabled    = true

  access_policy {
    tenant_id = data.azurerm_subscription.current.tenant_id
    object_id = var.spn_object_id

    key_permissions = [
      "List",
      "Get",
    ]

    secret_permissions = [
      "Set",
    ]
  }
  access_policy {
    tenant_id = data.azurerm_subscription.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Create",
      "List",
      "Delete",
      "Get",
      "Purge",
      "Recover",
      "Update",
      "GetRotationPolicy",
      "SetRotationPolicy"
    ]

    secret_permissions = [
      "Set",
    ]
  }
  
}

resource "azurerm_key_vault_key" "default" {
  count        = var.kv_name != "" ? 1:0
  name         = "cdp-default-key"
  key_vault_id = azurerm_key_vault.kv[0].id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]

  rotation_policy {
    automatic {
      time_before_expiry = "P30D"
    }

    expire_after         = "P90D"
    notify_before_expiry = "P29D"
  }
}

output "cmk_key_id" {
  value = var.kv_name != "" ? azurerm_key_vault_key.default[0].id : ""
}