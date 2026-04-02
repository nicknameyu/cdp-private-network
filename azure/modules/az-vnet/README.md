# az-vnet

Terraform module for provisioning an Azure Virtual Network (VNet) with support for standard subnets, delegated subnets, and network virtual appliance (NVA) subnets. Optionally creates the resource group that contains the network resources.

## Features

- Creates an Azure Virtual Network with a configurable address space
- Supports three subnet types:
  - **Standard subnets** — general-purpose subnets with an automatically created and associated route table (BGP propagation disabled)
  - **Delegated subnets** — subnets with service delegation for Azure PaaS services
  - **Appliance subnets** — subnets intended for Network Virtual Appliances (NVAs)
- All subnet types have service endpoints enabled for `Microsoft.Sql`, `Microsoft.Storage`, and `Microsoft.KeyVault`
- Optionally creates the resource group for the network resources

## Usage

```hcl
module "az_vnet" {
  source = "./modules/az-vnet"

  resource_group_name   = "rg-network"
  create_resource_group = true
  location              = "westus2"
  vnet_name             = "vnet-cdp"
  cidr                  = "10.0.0.0/16"

  std_subnets = {
    "subnet-app" = "10.0.1.0/24"
    "subnet-db"  = "10.0.2.0/24"
  }

  delegate_subnets = {
    "subnet-aks" = {
      prefix  = "10.0.3.0/24"
      service = "Microsoft.ContainerService/managedClusters"
    }
  }

  nva_subnets = {
    "subnet-nva" = "10.0.4.0/24"
  }

  tags = {
    environment = "production"
    team        = "platform"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| azurerm | >= 3.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | >= 3.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `resource_group_name` | Name of the resource group to hold the resources. | `string` | — | Yes |
| `vnet_name` | Name of the VNet to be created. | `string` | — | Yes |
| `cidr` | CIDR for the VNet. | `string` | — | Yes |
| `create_resource_group` | Whether to create the resource group. Set to `true` to create, `false` to use an existing group. | `bool` | `false` | No |
| `location` | Azure region where the resources will be created. | `string` | `"westus2"` | No |
| `std_subnets` | Standard subnets. `key` is the subnet name, `value` is the CIDR. A route table named `rt_<subnet-name>` is created and associated with each subnet. | `map(string)` | `{}` | No |
| `delegate_subnets` | Delegated subnets. `key` is the subnet name, `prefix` is the IP address space, `service` is the Azure service to delegate to. | `map(object({ prefix = string, service = string }))` | `{}` | No |
| `nva_subnets` | Appliance subnets for NVAs. `key` is the subnet name, `value` is the CIDR. | `map(string)` | `{}` | No |
| `tags` | Tags to apply to all resources. | `map(string)` | `null` | No |

## Outputs

| Name | Description |
|------|-------------|
| `resource_group_name` | Name of the resource group containing the network resources. |
| `vnet_id` | Resource ID of the created Virtual Network. |
| `std_subnet_ids` | Map of standard subnet names to their resource IDs. |
| `std_route_table_names` | Map of standard subnet names to their associated route table names. |
| `delegate_subnet_ids` | Map of delegated subnet names to their resource IDs. |
| `nva_subnet_ids` | Map of appliance subnet names to their resource IDs. |

## Resources

| Resource | Type |
|----------|------|
| `azurerm_resource_group.network` | resource |
| `azurerm_virtual_network.network` | resource |
| `azurerm_subnet.standard` | resource |
| `azurerm_route_table.standard` | resource |
| `azurerm_subnet_route_table_association.standard` | resource |
| `azurerm_subnet.svc_subnet` | resource |
| `azurerm_subnet.nva_subnet` | resource |

## Notes

- Route tables created for standard subnets have BGP route propagation **disabled** and are configured with `ignore_changes` on the `route` attribute, allowing routes to be managed outside of Terraform (e.g., by Azure Route Server or manual configuration) without causing drift.
- Delegated subnets include the `Microsoft.Network/virtualNetworks/subnets/join/action` delegation action explicitly to prevent Terraform from detecting spurious drift, as Azure adds this action automatically if omitted.
- When `create_resource_group = false`, the specified `resource_group_name` must already exist before applying.
