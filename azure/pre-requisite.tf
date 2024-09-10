resource "azurerm_resource_group" "prerequisite" {
  name     = var.resource_groups != null ? var.resource_groups.prerequisite_rg : "${var.owner}-cdp-prerequisite"
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

resource "azurerm_private_endpoint" "cdp" {
  name                = "${var.cdp_storage}-pe"
  location            = azurerm_resource_group.prerequisite.location
  resource_group_name = azurerm_resource_group.prerequisite.name
  subnet_id           = azurerm_subnet.cdp_subnets["subnet_26_1"].id

  private_service_connection {
    name                           = "${var.cdp_storage}-psc"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.cdp.id
    subresource_names              = ["dfs"]
  }
  private_dns_zone_group {
    name                 = "dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage.id]
  }
}

# Get the public ip of this terraform client
data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}
resource "azurerm_storage_account" "fileshare" {
  name                     = var.cdp_file_storage
  resource_group_name      = azurerm_resource_group.prerequisite.name
  location                 = azurerm_resource_group.prerequisite.location
  account_tier             = "Premium"
  account_replication_type = "LRS"
  account_kind             = "FileStorage"

  network_rules {
    default_action             = "Deny"
    ip_rules                   = [ chomp(data.http.myip.response_body) ]             // Public ip of this terraform client need to be in the storage account firewall
    virtual_network_subnet_ids = [ for subnet in azurerm_subnet.cdp_subnets: subnet.id ]
  }

  tags = var.tags
}
resource "azurerm_storage_share" "fileshare" {
  name                 = "cdp-ml-share"
  storage_account_name = azurerm_storage_account.fileshare.name
  quota                = 101                                      // this value must be greater than 100 for premium file storage
  enabled_protocol     = "NFS"

}
output "storage" {
  value = {
    storage-location-base = "data@${azurerm_storage_account.cdp.primary_dfs_host}"
    log-location          = "logs@${azurerm_storage_account.cdp.primary_dfs_host}"
    backup-location       = "backup@${azurerm_storage_account.cdp.primary_dfs_host}"
    nfs-file-share        = "nfs://${azurerm_storage_account.fileshare.primary_file_host}:/${var.cdp_file_storage}/${azurerm_storage_share.fileshare.name}"
  }
}
############## Managed Identity #################
resource "azurerm_user_assigned_identity" "managed_id" {
  for_each            = var.managed_id != null ? var.managed_id : {
                                                                    assumer    = "${var.owner}-cdp-assumer"
                                                                    dataaccess = "${var.owner}-cdp-dataaccess"
                                                                    logger     = "${var.owner}-cdp-logger"
                                                                    ranger     = "${var.owner}-cdp-ranger"
                                                                    raz        = "${var.owner}-cdp-raz"
                                                                  }
  location            = azurerm_resource_group.prerequisite.location
  name                = each.value
  resource_group_name = azurerm_resource_group.prerequisite.name
}

data azurerm_subscription "current"{}
data "azurerm_client_config" "current" {}
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
        principal_id = azurerm_user_assigned_identity.managed_id["dataaccess"].principal_id
        scope = "/subscriptions/${data.azurerm_subscription.current.subscription_id}"
        role  = azurerm_role_definition.dw.name
      },
      dw2 = {                                                                                     // Attention: this one is not listed in document, but it is necessary
        principal_id = azurerm_user_assigned_identity.managed_id["dataaccess"].principal_id
        scope = "/subscriptions/${data.azurerm_subscription.current.subscription_id}"
        role  = "Managed Identity Operator"        
      },
      spn_main = {
        principal_id = var.spn_object_id
        scope = "/subscriptions/${data.azurerm_subscription.current.subscription_id}"
        role  = var.spn_permision_contributor ? "Contributor" : azurerm_role_definition.env_single_rg_pvt_ep.name
      },
      spn_cmk = {
        principal_id = var.spn_object_id
        scope = "/subscriptions/${data.azurerm_subscription.current.subscription_id}"
        role  = azurerm_role_definition.cmk.name
      },
      spn_dw = {
        principal_id = var.spn_object_id
        scope = "/subscriptions/${data.azurerm_subscription.current.subscription_id}"
        role  = azurerm_role_definition.dw.name
      },
      spn_liftie = {
        principal_id = var.spn_object_id
        scope = "/subscriptions/${data.azurerm_subscription.current.subscription_id}"
        role  = azurerm_role_definition.liftie.name
      },
      spn_mkt_img = {
        principal_id = var.spn_object_id
        scope = "/subscriptions/${data.azurerm_subscription.current.subscription_id}"
        role  = azurerm_role_definition.mkt_img.name
      }
  }
}

resource "time_sleep" "custom_role" {
  // Adding this sleep resource to create a delay between creating the custom roles and role assignment.
  depends_on =  [
                  azurerm_role_definition.cmk,
                  azurerm_role_definition.dw,
                  azurerm_role_definition.env_single_rg_pvt_ep,
                  azurerm_role_definition.env_single_rg_svc_ep,
                  azurerm_role_definition.liftie,
                  azurerm_role_definition.mkt_img
                ]

  create_duration = "180s"
}

resource "azurerm_role_assignment" "assignment" {
  for_each             = local.role_assignment
  scope                = each.value["scope"]
  role_definition_name = each.value["role"]
  principal_id         = each.value["principal_id"]
  depends_on           = [ time_sleep.custom_role ]
}

############### CDP Security Group ####################
resource "azurerm_network_security_group" "default" {
  for_each            = toset(["${var.owner}-nsg-default", "${var.owner}-nsg-knox"])
  name                = each.key
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name

  security_rule {
    name                       = "ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = [var.cdp_cidr, var.hub_cidr]
    destination_address_prefix = var.cdp_cidr
  }
  security_rule {
    name                       = "https"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefixes    = [var.cdp_cidr, var.hub_cidr]
    destination_address_prefix = var.cdp_cidr
  }
  security_rule {
    name                       = "mgmt"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9443"
    source_address_prefixes    = [var.cdp_cidr, var.hub_cidr]
    destination_address_prefix = var.cdp_cidr
  }
  security_rule {
    name                       = "comm-tcp"
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "0-65535"
    source_address_prefix      = var.cdp_cidr
    destination_address_prefix = var.cdp_cidr
  }
  security_rule {
    name                       = "comm-udp"
    priority                   = 104
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "0-65535"
    source_address_prefix      = var.cdp_cidr
    destination_address_prefix = var.cdp_cidr
  }
  security_rule {
    name                       = "icmp"
    priority                   = 105
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = [var.cdp_cidr, var.hub_cidr]
    destination_address_prefix = var.cdp_cidr
  }
  tags = var.tags
}


output "ssh_public_key" {
  value = file(var.public_key)
}