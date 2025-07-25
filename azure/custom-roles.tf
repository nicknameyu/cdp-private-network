resource "azurerm_role_definition" "dw" {
  name        = var.custom_role_names == null ? "${var.owner} CDP DW" : var.custom_role_names.dw
  scope       = data.azurerm_subscription.current.id
  description = var.custom_role_names == null ? "${var.owner} CDP DW" : var.custom_role_names.dw

  permissions {
    actions     = [                   
      "Microsoft.Resources/deployments/cancel/action",
      "Microsoft.Resources/deployments/validate/action",
      "Microsoft.ContainerService/managedClusters/write",
      "Microsoft.ContainerService/managedClusters/agentPools/write",
      "Microsoft.ContainerService/managedClusters/read",
      "Microsoft.ContainerService/managedClusters/agentPools/read",
      "Microsoft.ContainerService/managedClusters/accessProfiles/listCredential/action",
      "Microsoft.ContainerService/managedClusters/delete",
      "Microsoft.ContainerService/managedClusters/rotateClusterCertificates/action",
      "Microsoft.DBforPostgreSQL/flexibleServers/read",
      "Microsoft.DBforPostgreSQL/flexibleServers/write",
      "Microsoft.DBforPostgreSQL/flexibleServers/delete",
      "Microsoft.DBforPostgreSQL/flexibleServers/firewallRules/write",
      "Microsoft.DBforPostgreSQL/flexibleServers/firewallRules/read",
      "Microsoft.DBforPostgreSQL/flexibleServers/firewallRules/delete",
      "Microsoft.DBforPostgreSQL/flexibleServers/configurations/read",
      "Microsoft.DBforPostgreSQL/flexibleServers/configurations/write",
      "Microsoft.DBforPostgreSQL/flexibleServers/databases/read",
      "Microsoft.DBforPostgreSQL/flexibleServers/databases/write",
      "Microsoft.DBforPostgreSQL/flexibleServers/databases/delete",
      "Microsoft.DBforPostgreSQL/servers/virtualNetworkRules/write",
      "Microsoft.DBforPostgreSQL/servers/databases/write",
      "Microsoft.Network/privateDnsZones/A/read",
      "Microsoft.Network/privateDnsZones/A/write",
      "Microsoft.Network/privateDnsZones/A/delete",
      "Microsoft.Network/privateDnsZones/virtualNetworkLinks/read",
      "Microsoft.Network/virtualNetworks/subnets/joinViaServiceEndpoint/action",
      "Microsoft.Network/virtualNetworks/subnets/read",                                 // added with testing result 07/20/2023
      "Microsoft.Network/virtualNetworks/subnets/join/action",                          // added with testing result 07/20/2023
      "Microsoft.Network/loadBalancers/write",                                          // added with testing result 07/20/2023
      "Microsoft.Network/routeTables/read",
      "Microsoft.Network/routeTables/write",
      "Microsoft.Network/routeTables/routes/read",
      "Microsoft.Network/routeTables/routes/write",
      "Microsoft.Network/routeTables/join/action",
      "Microsoft.Network/natGateways/join/action",
      "Microsoft.Network/virtualNetworks/subnets/joinLoadBalancer/action",
      "Microsoft.Network/privateDnsZones/write",
      "Microsoft.Network/privateDnsZones/read",
      "Microsoft.Network/privateDnsZones/virtualNetworkLinks/write",
      "Microsoft.Network/privateEndpoints/write",
      "Microsoft.Network/privateEndpoints/read",
      "Microsoft.Network/privateEndpoints/privateDnsZoneGroups/read",
      "Microsoft.Network/privateEndpoints/privateDnsZoneGroups/write",
      "Microsoft.Network/privateEndpoints/privateDnsZoneGroups/delete",
      "Microsoft.Network/privateDnsZones/join/action"
    ]

  }

  assignable_scopes = [
    data.azurerm_subscription.current.id, # /subscriptions/00000000-0000-0000-0000-000000000000
  ]
}

resource "azurerm_role_definition" "dns_zone" {
  name        = var.custom_role_names == null ? "${var.owner} DNS Zone" : var.custom_role_names.dns_zone
  scope       = var.dns_zone_subscription_id != null ? "/subscriptions/${var.dns_zone_subscription_id}" : data.azurerm_subscription.current.id
  provider    = azurerm.secondary
  description = var.custom_role_names == null ? "${var.owner} DNS Zone" : var.custom_role_names.dns_zone
  permissions {
    actions     = [                   
      "Microsoft.Network/privateDnsZones/A/read",
      "Microsoft.Network/privateDnsZones/A/write",
      "Microsoft.Network/privateDnsZones/A/delete",
      "Microsoft.Network/privateDnsZones/virtualNetworkLinks/read",
      "Microsoft.Network/privateDnsZones/read",
      "Microsoft.Network/privateDnsZones/write"
    ]
  }
  assignable_scopes = [
    var.dns_zone_subscription_id != null ? "/subscriptions/${var.dns_zone_subscription_id}" : data.azurerm_subscription.current.id # /subscriptions/00000000-0000-0000-0000-000000000000
  ]
}


# Normally customer would agree to assign Azure native blob storage native roles, "Storage Blob Data Owner" and 
# "Storage Blob Data Delegator" at storage account level.
# This resource is required if customer do not want to assign RAZ identity with Azure native roles.
# resource "azurerm_role_definition" "raz" {
#   name        = "DYU CDP RAZ"
#   scope       = data.azurerm_subscription.current.id
#   description = "DYU CDP RAZ"

#   permissions {
#     actions     = ["Microsoft.Storage/storageAccounts/blobServices/generateUserDelegationKey/action"]
#     not_actions = []
#     data_actions = ["Microsoft.Storage/storageAccounts/blobServices/containers/blobs/manageOwnership/action",
#                     "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/modifyPermissions/action",
#                     "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read",
#                     "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/write",
#                     "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/delete",
#                     "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/move/action"
#                   ]
#     not_data_actions = []
#   }

#   assignable_scopes = [
#     data.azurerm_subscription.current.id, # /subscriptions/00000000-0000-0000-0000-000000000000
#   ]
# }

resource "azurerm_role_definition" "liftie" {
  name        = var.custom_role_names == null ? "${var.owner} CDP Liftie" : var.custom_role_names.liftie
  scope       = data.azurerm_subscription.current.id
  description = var.custom_role_names == null ? "${var.owner} CDP Liftie" : var.custom_role_names.liftie

  permissions {
    actions     = [                   
      "Microsoft.ContainerService/managedClusters/read",
      "Microsoft.ContainerService/managedClusters/write",
      "Microsoft.ContainerService/managedClusters/agentPools/read",
      "Microsoft.ContainerService/managedClusters/agentPools/write",
      "Microsoft.ContainerService/managedClusters/upgradeProfiles/read",
			"Microsoft.ContainerService/managedClusters/agentPools/delete",
      "Microsoft.ContainerService/managedClusters/delete",
      "Microsoft.ContainerService/managedClusters/accessProfiles/listCredential/action",
      "Microsoft.ContainerService/managedClusters/agentPools/upgradeProfiles/read",
      "Microsoft.Storage/storageAccounts/read",
      "Microsoft.Storage/storageAccounts/write",
      "Microsoft.ManagedIdentity/userAssignedIdentities/assign/action",
      "Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials/*",   # added base on doc update on 04/08/2025
      "Microsoft.Insights/metrics/read",                                                   # added base on doc update on 04/08/2025
      "Microsoft.Insights/metricDefinitions/read",                                         # added base on doc update on 04/08/2025
      "Microsoft.Compute/virtualMachineScaleSets/write",
      "Microsoft.Network/virtualNetworks/subnets/join/action",
      "Microsoft.Network/virtualNetworks/subnets/read",
      "Microsoft.Network/routeTables/read",
      "Microsoft.Network/routeTables/write",
      "Microsoft.Network/routeTables/routes/read",
      "Microsoft.Network/routeTables/routes/write"
    ]

  }

  assignable_scopes = [
    data.azurerm_subscription.current.id, # /subscriptions/00000000-0000-0000-0000-000000000000
  ]
}


resource "azurerm_role_definition" "datalake" {
  name        = var.custom_role_names == null ? "${var.owner} datalake" : var.custom_role_names.datalake
  scope       = data.azurerm_subscription.current.id
  description = var.custom_role_names == null ? "${var.owner} datalake" : var.custom_role_names.datalake

  permissions {
    actions     = [
      "Microsoft.Storage/storageAccounts/read",
      "Microsoft.Storage/storageAccounts/write",
      "Microsoft.Storage/storageAccounts/blobServices/write",
      "Microsoft.Storage/storageAccounts/blobServices/containers/delete",
      "Microsoft.Storage/storageAccounts/blobServices/containers/read",
      "Microsoft.Storage/storageAccounts/blobServices/containers/write",
      "Microsoft.Storage/storageAccounts/fileServices/write",
      "Microsoft.Storage/storageAccounts/listkeys/action",
      "Microsoft.Storage/storageAccounts/regeneratekey/action",
      "Microsoft.Storage/storageAccounts/delete",
      "Microsoft.Storage/locations/deleteVirtualNetworkOrSubnets/action",
      "Microsoft.Network/virtualNetworks/read",
      "Microsoft.Network/virtualNetworks/write",
      "Microsoft.Network/virtualNetworks/delete",
      "Microsoft.Network/virtualNetworks/subnets/read",
      "Microsoft.Network/virtualNetworks/subnets/write",
      "Microsoft.Network/virtualNetworks/subnets/delete",
      "Microsoft.Network/virtualNetworks/subnets/join/action",
      "Microsoft.Network/publicIPAddresses/read",
      "Microsoft.Network/publicIPAddresses/write",
      "Microsoft.Network/publicIPAddresses/delete",
      "Microsoft.Network/publicIPAddresses/join/action",
      "Microsoft.Network/networkInterfaces/read",
      "Microsoft.Network/networkInterfaces/write",
      "Microsoft.Network/networkInterfaces/delete",
      "Microsoft.Network/networkInterfaces/join/action",
      "Microsoft.Network/networkInterfaces/ipconfigurations/read",
      "Microsoft.Network/networkSecurityGroups/read",
      "Microsoft.Network/networkSecurityGroups/write",
      "Microsoft.Network/networkSecurityGroups/delete",
      "Microsoft.Network/networkSecurityGroups/join/action",
      "Microsoft.Compute/availabilitySets/read",
      "Microsoft.Compute/availabilitySets/write",
      "Microsoft.Compute/availabilitySets/delete",
      "Microsoft.Compute/disks/read",
      "Microsoft.Compute/disks/write",
      "Microsoft.Compute/disks/delete",
      "Microsoft.Compute/images/read",
      "Microsoft.Compute/images/write",
      "Microsoft.Compute/images/delete",
      "Microsoft.Compute/virtualMachines/read",
      "Microsoft.Compute/virtualMachines/write",
      "Microsoft.Compute/virtualMachines/delete",
      "Microsoft.Compute/virtualMachines/powerOff/action",
      "Microsoft.Compute/virtualMachines/start/action",
      "Microsoft.Compute/virtualMachines/restart/action",
      "Microsoft.Compute/virtualMachines/deallocate/action",
      "Microsoft.Compute/virtualMachines/vmSizes/read",
      "Microsoft.Authorization/roleAssignments/read",
      "Microsoft.Resources/subscriptions/resourceGroups/read",
      "Microsoft.Resources/deployments/read",
      "Microsoft.Resources/deployments/write",
      "Microsoft.Resources/deployments/delete",
      "Microsoft.Resources/deployments/operations/read",
      "Microsoft.Resources/deployments/operationstatuses/read",
      "Microsoft.Resources/deployments/exportTemplate/action",
      "Microsoft.Resources/subscriptions/read",
      "Microsoft.ManagedIdentity/userAssignedIdentities/read",
      "Microsoft.ManagedIdentity/userAssignedIdentities/assign/action",
      "Microsoft.DBforPostgreSQL/flexibleServers/PrivateEndpointConnectionsApproval/action",  // added base on testing 09/04/2024 for supporting privatelink for postgres db flexible server
      "Microsoft.DBforPostgreSQL/servers/read",
      "Microsoft.DBforPostgreSQL/servers/write",
      "Microsoft.DBforPostgreSQL/servers/delete",
      "Microsoft.DBforPostgreSQL/flexibleServers/read",
      "Microsoft.DBforPostgreSQL/flexibleServers/write",
      "Microsoft.DBforPostgreSQL/flexibleServers/delete",
      "Microsoft.DBforPostgreSQL/flexibleServers/start/action",
      "Microsoft.DBforPostgreSQL/flexibleServers/stop/action",
      "Microsoft.DBforPostgreSQL/flexibleServers/firewallRules/write",
      "Microsoft.DBforPostgreSQL/flexibleServers/start/action",                // added base on testing 03/25/2024
      "Microsoft.DBforPostgreSQL/flexibleServers/stop/action",                 // added base on testing 03/25/2024
      "Microsoft.DBforMySQL/flexibleServers/read",                             // added base on testing 03/25/2024
      "Microsoft.DBforMySQL/flexibleServers/write",                            // added base on testing 03/25/2024
      "Microsoft.DBforMySQL/flexibleServers/delete",                           // added base on testing 03/25/2024
      "Microsoft.DBforMySQL/flexibleServers/start/action",                     // added base on testing 03/25/2024
      "Microsoft.DBforMySQL/flexibleServers/stop/action",                      // added base on testing 03/25/2024
      "Microsoft.DBforMySQL/flexibleServers/firewallRules/write",              // added base on testing 03/25/2024
      "Microsoft.DBforMySQL/flexibleServers/start/action",                     // added base on testing 03/25/2024
      "Microsoft.DBforMySQL/flexibleServers/stop/action",                      // added base on testing 03/25/2024
      "Microsoft.DBforMySQL/flexibleServers/PrivateEndpointConnectionsApproval/action", // added base on testing 03/25/2024
      "Microsoft.Network/privateDnsZones/read",
      "Microsoft.Network/privateEndpoints/read",
      "Microsoft.Network/privateEndpoints/write",
      "Microsoft.Network/privateEndpoints/delete",
      "Microsoft.Network/privateEndpoints/privateDnsZoneGroups/read",
      "Microsoft.Network/privateEndpoints/privateDnsZoneGroups/write",
      "Microsoft.DBforPostgreSQL/servers/privateEndpointConnectionsApproval/action",
      "Microsoft.DBforPostgreSQL/flexibleServers/privateEndpointConnectionsApproval/action",    // Added base on testing 01/10/2025
      "Microsoft.DBforPostgreSQL/flexibleServers/privateEndpointConnections/read",              // Added base on testing 01/10/2025
      "Microsoft.DBforPostgreSQL/flexibleServers/privateEndpointConnections/delete",            // Added base on testing 01/10/2025
      "Microsoft.DBforPostgreSQL/flexibleServers/privateEndpointConnections/write",             // Added base on testing 01/10/2025
      "Microsoft.Network/privateDnsZones/A/read",
      "Microsoft.Network/privateDnsZones/A/write",
      "Microsoft.Network/privateDnsZones/A/delete",
      "Microsoft.Network/privateDnsZones/join/action",
      "Microsoft.Network/privateDnsZones/write",
      "Microsoft.Network/privateDnsZones/delete",
      "Microsoft.Network/privateDnsZones/virtualNetworkLinks/read", 
      "Microsoft.Network/privateDnsZones/virtualNetworkLinks/write",
      "Microsoft.Network/privateDnsZones/virtualNetworkLinks/delete",        
      "Microsoft.Network/virtualNetworks/join/action",
      "Microsoft.Network/loadBalancers/delete",
      "Microsoft.Network/loadBalancers/read",
      "Microsoft.Network/loadBalancers/write",
      "Microsoft.Network/loadBalancers/backendAddressPools/join/action",
      "Microsoft.Resources/deployments/cancel/action",
      "Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials/write",            // Added 9/10/2024 with testing for DE service
    ]
    data_actions = [
      "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read",
      "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/write",
      "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/delete",
      "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/add/action"
    ]

  }

  assignable_scopes = [
    data.azurerm_subscription.current.id, # /subscriptions/00000000-0000-0000-0000-000000000000
  ]
}

resource "azurerm_role_definition" "cmk" {
  name        = var.custom_role_names == null ? "${var.owner} CDP CMK" : var.custom_role_names.cmk
  scope       = data.azurerm_subscription.current.id
  description = var.custom_role_names == null ? "${var.owner} CDP CMK" : var.custom_role_names.cmk

  permissions {
    actions     = [
      "Microsoft.KeyVault/vaults/read",
      "Microsoft.KeyVault/vaults/write",
      "Microsoft.KeyVault/vaults/secrets/write",
      "Microsoft.KeyVault/vaults/secrets/read",
      "Microsoft.KeyVault/vaults/keys/write",
      "Microsoft.KeyVault/vaults/keys/read",
      "Microsoft.KeyVault/vaults/deploy/action",
      "Microsoft.Compute/diskEncryptionSets/read",
      "Microsoft.Compute/diskEncryptionSets/write",
      "Microsoft.Compute/diskEncryptionSets/delete",
      "Microsoft.DBforPostgreSQL/servers/read",
      "Microsoft.DBforPostgreSQL/servers/keys/write",
      "Microsoft.KeyVault/vaults/accessPolicies/write"
    ]
    data_actions = [
      "Microsoft.KeyVault/vaults/keys/read", 
      "Microsoft.KeyVault/vaults/keys/wrap/action", 
      "Microsoft.KeyVault/vaults/keys/unwrap/action"
    ]

  }

  assignable_scopes = [
    data.azurerm_subscription.current.id, # /subscriptions/00000000-0000-0000-0000-000000000000
  ]
}

resource "azurerm_role_definition" "mkt_img" {
  name        = var.custom_role_names == null ? "${var.owner} CDP Mkt Image" : var.custom_role_names.mkt_img
  scope       = data.azurerm_subscription.current.id
  description = var.custom_role_names == null ? "${var.owner} CDP Mkt Image" : var.custom_role_names.mkt_img

  permissions {
    actions     = [
                    "Microsoft.MarketplaceOrdering/offertypes/publishers/offers/plans/agreements/read",
                    "Microsoft.MarketplaceOrdering/offertypes/publishers/offers/plans/agreements/write" 
    ]

  }

  assignable_scopes = [
    data.azurerm_subscription.current.id, # /subscriptions/00000000-0000-0000-0000-000000000000
  ]
}