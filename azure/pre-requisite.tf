resource "azurerm_resource_group" "prerequisite" {
  name     = var.resource_groups.prerequisite_rg
  location = var.location
  tags = var.tags
}

############# Storage ############
resource "azurerm_storage_account" "cdp" {
  name                     = var.cdp_storage
  resource_group_name      = azurerm_resource_group.prerequisite.name
  location                 = azurerm_resource_group.prerequisite.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true

  tags = var.tags
}

resource "azurerm_storage_container" "containers" {
  for_each              = toset(["data", "logs", "backup"])
  name                  = each.key
  storage_account_name  = azurerm_storage_account.cdp.name
  container_access_type = "private"
}

############## Managed Identity #################
resource "azurerm_user_assigned_identity" "managed_id" {
  for_each            = var.managed_id
  location            = azurerm_resource_group.prerequisite.location
  name                = each.value
  resource_group_name = azurerm_resource_group.prerequisite.name
}

data azurerm_subscription "current"{}
locals {
  role_assignment = {
      assumer1 = {
        principal_id = azurerm_user_assigned_identity.managed_id["assumer"].principal_id
        scope = "/subscriptions/${data.azurerm_subscription.current.subscription_id}"
        role  = "Managed Identity Operator"     //Managed Identity Operator role 
      },
      assumer2 = {
        principal_id = azurerm_user_assigned_identity.managed_id["assumer"].principal_id
        scope = "/subscriptions/${data.azurerm_subscription.current.subscription_id}"
        role  = "Virtual Machine Contributor"     //Virtual Machine Contributor role
      },
      assumer3 = {
        principal_id = azurerm_user_assigned_identity.managed_id["assumer"].principal_id
        scope = azurerm_storage_container.containers["logs"].resource_manager_id
        role  = "Storage Blob Data Contributor"     //Storage Blob Data Contributor role
      },
      dataaccess1 = {
        principal_id = azurerm_user_assigned_identity.managed_id["dataaccess"].principal_id
        scope = azurerm_storage_container.containers["logs"].resource_manager_id
        role  = "Storage Blob Data Owner"     //Storage Blob Data Owner role
      },
      dataaccess2 = {
        principal_id = azurerm_user_assigned_identity.managed_id["dataaccess"].principal_id
        scope = azurerm_storage_container.containers["data"].resource_manager_id
        role  = "Storage Blob Data Owner"     //Storage Blob Data Owner role
      },
      dataaccess3 = {
        principal_id = azurerm_user_assigned_identity.managed_id["dataaccess"].principal_id
        scope = azurerm_storage_container.containers["backup"].resource_manager_id
        role  = "Storage Blob Data Owner"     //Storage Blob Data Owner role
      },
      logger1 = {
        principal_id = azurerm_user_assigned_identity.managed_id["logger"].principal_id
        scope = azurerm_storage_container.containers["logs"].resource_manager_id
        role  = "Storage Blob Data Contributor"     //Storage Blob Data Contributor role
      },
      logger2 = {
        principal_id = azurerm_user_assigned_identity.managed_id["logger"].principal_id
        scope = azurerm_storage_container.containers["backup"].resource_manager_id
        role  = "Storage Blob Data Contributor"     //Storage Blob Data Contributor role
      },
      ranger1 = {
        principal_id = azurerm_user_assigned_identity.managed_id["ranger"].principal_id
        scope = azurerm_storage_container.containers["data"].resource_manager_id
        role  = "Storage Blob Data Contributor"     //Storage Blob Data Contributor role
      },
      ranger2 = {
        principal_id = azurerm_user_assigned_identity.managed_id["ranger"].principal_id
        scope = azurerm_storage_container.containers["logs"].resource_manager_id
        role  = "Storage Blob Data Contributor"     //Storage Blob Data Contributor role
      },
      ranger3 = {
        principal_id = azurerm_user_assigned_identity.managed_id["ranger"].principal_id
        scope = azurerm_storage_container.containers["backup"].resource_manager_id
        role  = "Storage Blob Data Contributor"     //Storage Blob Data Contributor role
      },
      raz1 = {
        principal_id = azurerm_user_assigned_identity.managed_id["raz"].principal_id
        scope = azurerm_storage_account.cdp.id
        role  = "Storage Blob Data Owner"
      },
      raz2 = {
        principal_id = azurerm_user_assigned_identity.managed_id["raz"].principal_id
        scope = azurerm_storage_account.cdp.id
        role  = "Storage Blob Delegator"
      },
      dw1  = {
        principal_id = azurerm_user_assigned_identity.managed_id["dw"].principal_id
        scope = "/subscriptions/${data.azurerm_subscription.current.subscription_id}"
        role  = azurerm_role_definition.dw.name
      },
      dw2 = {
        principal_id = azurerm_user_assigned_identity.managed_id["dw"].principal_id
        scope = "/subscriptions/${data.azurerm_subscription.current.subscription_id}"
        role  = "Managed Identity Operator"        
      }
  }
}

resource "azurerm_role_assignment" "assignment" {
  for_each             = local.role_assignment
  scope                = each.value["scope"]
  role_definition_name = each.value["role"]
  principal_id         = each.value["principal_id"]
  depends_on           = [ 
                            azurerm_role_definition.cmk,
                            azurerm_role_definition.dw,
                            azurerm_role_definition.env_multi_rg_pvt_ep,
                            azurerm_role_definition.env_single_rg_pvt_ep,
                            azurerm_role_definition.env_single_rg_svc_ep,
                            azurerm_role_definition.liftie
                         ]
}

