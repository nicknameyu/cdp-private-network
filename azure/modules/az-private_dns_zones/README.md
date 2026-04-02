# az-private_dns_zones

A Terraform module for creating and managing Azure Private DNS Zones and their virtual network links. Designed for use with Cloudera Data Platform (CDP) private network deployments, this module supports centralized hub-subscription DNS architectures commonly used in enterprise environments.

## Overview

This module:

- Optionally creates or references an existing Azure Resource Group for DNS resources
- Provisions a configurable set of Private DNS Zones (defaulting to zones required for AKS, PostgreSQL, MySQL, and Azure Data Lake Storage Gen2)
- Links each DNS zone to one or more Virtual Networks (VNets)

The module uses an aliased `azurerm` provider (`azurerm.secondary`) to support deploying DNS zones into a **separate subscription** from the workload — a common pattern where DNS is managed in a centralized hub subscription.

## Usage

```hcl
module "private_dns_zones" {
  source = "./modules/az-private_dns_zones"

  providers = {
    azurerm.secondary = azurerm.dns_subscription
  }

  location              = "eastus"
  resource_group_name   = "rg-cdp-private-dns"
  create_resource_group = true
  subscription_id       = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

  vnet_ids = {
    hub   = "/subscriptions/.../virtualNetworks/hub-vnet"
    spoke = "/subscriptions/.../virtualNetworks/spoke-vnet"
  }

  tags = {
    environment = "production"
    project     = "cdp"
  }
}
```

### Using custom DNS zones

```hcl
module "private_dns_zones" {
  source = "./modules/az-private_dns_zones"

  providers = {
    azurerm.secondary = azurerm.dns_subscription
  }

  resource_group_name = "rg-cdp-private-dns"
  location            = "westus2"

  private_dns_zones = {
    aks     = "privatelink.westus2.azmk8s.io"
    pgdb    = "privatelink.postgres.database.azure.com"
    mysql   = "privatelink.mysql.database.azure.com"
    storage = "privatelink.dfs.core.windows.net"
    keyvault = "privatelink.vaultcore.azure.net"
  }

  vnet_ids = {
    hub = "/subscriptions/.../virtualNetworks/hub-vnet"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| azurerm | >= 3.0 |

## Providers

This module requires an aliased provider named `azurerm.secondary`. This provider is used for all resource creation and can point to either the same subscription as the caller or a dedicated hub/DNS subscription.

```hcl
provider "azurerm" {
  alias           = "secondary"
  subscription_id = "<dns-hub-subscription-id>"
  features {}
}
```

## Inputs

| Name | Type | Default | Required | Description |
|------|------|---------|----------|-------------|
| `resource_group_name` | `string` | — | **yes** | Name of the resource group for Private DNS zones. |
| `location` | `string` | `"westus2"` | no | Azure region where resources will be created. |
| `subscription_id` | `string` | `""` | no | Subscription ID for the DNS zones. Defaults to the current subscription when empty. |
| `create_resource_group` | `bool` | `true` | no | If `true`, creates the resource group. If `false`, uses an existing one. |
| `private_dns_zones` | `map(string)` | `null` | no | Map of key → DNS zone name. When `null`, defaults to the four standard CDP zones (see below). |
| `vnet_ids` | `map(string)` | `{}` | no | Map of key → VNet resource ID. Each VNet will be linked to all DNS zones. Example: `{ hub = "<vnet-id>", spoke = "<vnet-id>" }` |
| `tags` | `map(string)` | `null` | no | Tags to apply to all created resources. |

### Default DNS Zones

When `private_dns_zones` is left as `null`, the following zones are created (using the specified `location` for the AKS zone):

| Key | DNS Zone |
|-----|----------|
| `aks` | `privatelink.<location>.azmk8s.io` |
| `pgdb` | `privatelink.postgres.database.azure.com` |
| `mysql` | `privatelink.mysql.database.azure.com` |
| `storage` | `privatelink.dfs.core.windows.net` |

## Outputs

| Name | Type | Description |
|------|------|-------------|
| `private_dns_zones` | `map(string)` | Map of DNS zone key → Azure resource ID for each created Private DNS Zone. |

## Resources

| Resource | Type |
|----------|------|
| `azurerm_resource_group.dns` | Created when `create_resource_group = true` |
| `data.azurerm_resource_group.dns` | Referenced when `create_resource_group = false` |
| `azurerm_private_dns_zone.dns` | One per entry in `private_dns_zones` |
| `azurerm_private_dns_zone_virtual_network_link.dns` | One per DNS zone × VNet combination |

## Notes

- **Cross-subscription support**: Set `subscription_id` to deploy DNS zones into a centralized hub subscription while workloads run in a separate spoke subscription. This is a recommended pattern for enterprise CDP deployments.
- **VNet links**: All specified VNets are linked to **all** DNS zones. The link name follows the pattern `<vnet-key>-<zone-key>`.
- **Idempotency**: Re-applying with the same inputs is safe. Adding new VNets or DNS zones will only create the new links/zones without affecting existing ones.