# az-firewall Terraform Module

This module deploys an **Azure Firewall** configured with the egress rules required for [Cloudera Data Platform (CDP)](https://www.cloudera.com/products/cloudera-data-platform.html) private network environments. It provisions the firewall, attaches a static public IP, and automatically routes internet-bound traffic from specified subnets through the firewall as a Network Virtual Appliance (NVA).

## Features

- Creates an Azure Firewall (Standard SKU) with a static public IP
- Optionally creates a dedicated resource group
- Automatically adds a default route (`0.0.0.0/0 → VirtualAppliance`) to the route tables of all specified subnets
- Provisions pre-configured **application rule collections** (HTTP/HTTPS) covering:
  - CDP Control Plane endpoints (US, EU, AP regions)
  - Docker / container registries (Cloudera, Docker Hub, Quay, GCR, MCR)
  - Azure services (AKS, Azure Policy, Log Analytics, Automation)
  - Package repositories (Ubuntu, PyPI, HashiCorp, Snap, CentOS)
  - NVIDIA GPU drivers, GitHub tooling, and more
- Provisions pre-configured **network rule collections** for CDP Control Plane IP ranges (US, EU, AP regions)

## Usage

```hcl
module "az_firewall" {
  source = "./modules/az-firewall"

  location              = "westus2"
  resource_group_name   = "rg-cdp-network"
  create_resource_group = false

  firewall_name      = "cdp-firewall"
  firewall_subnet_id = "/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Network/virtualNetworks/<vnet>/subnets/AzureFirewallSubnet"

  egress_source_cidrs = ["10.0.0.0/16"]

  subnets = {
    "subnet-workload-1" = "/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Network/virtualNetworks/<vnet>/subnets/subnet-workload-1"
    "subnet-workload-2" = "/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Network/virtualNetworks/<vnet>/subnets/subnet-workload-2"
  }

  tags = {
    environment = "production"
    owner       = "platform-team"
  }
}
```

> **Note:** The firewall subnet must be named `AzureFirewallSubnet` and have a minimum size of `/26`, as required by Azure.

## Requirements

| Name | Version |
|------|---------|
| Terraform | >= 1.0 |
| azurerm | >= 3.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | >= 3.0 |

## Resources Created

| Resource | Type | Description |
|----------|------|-------------|
| `azurerm_resource_group.network` | Resource (conditional) | Resource group, created only if `create_resource_group = true` |
| `azurerm_public_ip.firewall` | Resource | Static Standard public IP for the firewall |
| `azurerm_firewall.firewall` | Resource | Azure Firewall (AZFW_VNet, Standard tier) |
| `azurerm_route.internet` | Resource (per subnet) | Default route pointing to the firewall's private IP |
| `azurerm_firewall_application_rule_collection.app_rules` | Resource | Application rules for HTTP/HTTPS egress (priority 120) |
| `azurerm_firewall_network_rule_collection.network_rules` | Resource | Network rules for CDP Control Plane IPs (priority 130) |

## Input Variables

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `location` | `string` | No | `"westus2"` | Azure region where resources will be created. |
| `resource_group_name` | `string` | **Yes** | — | Name of the resource group to hold the resources. |
| `create_resource_group` | `bool` | No | `false` | Whether to create the resource group. Set to `true` if it doesn't already exist. |
| `firewall_name` | `string` | **Yes** | — | Name of the Azure Firewall resource. |
| `firewall_subnet_id` | `string` | **Yes** | — | Azure resource ID of the `AzureFirewallSubnet` subnet. |
| `egress_source_cidrs` | `list(string)` | **Yes** | — | List of source CIDRs (private network ranges) permitted for outbound traffic through the firewall. |
| `subnets` | `map(string)` | **Yes** | — | Map of `subnet_name → subnet_resource_id` for subnets that should route egress through this firewall. |
| `tags` | `map(string)` | No | `null` | Tags to apply to all created resources. |
| `fw_app_rules` | `map(object)` | No | See [firewall_rules.tf] | Application firewall rules (HTTPS/HTTP). Override to customize allowed FQDNs. |
| `fw_net_rules` | `map(object)` | No | See [firewall_rules.tf] | Network firewall rules for CDP Control Plane IP ranges. Override to customize. |

## Outputs

| Name | Description |
|------|-------------|
| `firewapp_internal_ip` | The private IP address of the Azure Firewall. Use this as the next-hop address in custom route tables. |

## Firewall Rules

### Application Rules (HTTPS — port 443)

The default HTTPS allow-list covers the following categories:

| Category | Example Endpoints |
|----------|-------------------|
| CDP Control Plane (US) | `api.us-west-1.cdp.cloudera.com`, `dbusapi.us-west-1.sigma.altus.cloudera.com` |
| CDP Control Plane (EU) | `api.eu-1.cdp.cloudera.com`, `console.eu-1.cdp.cloudera.com` |
| CDP Control Plane (AP) | `api.ap-1.cdp.cloudera.com`, `console.ap-1.cdp.cloudera.com` |
| Cloudera Parcels & Repos | `archive.cloudera.com` |
| Docker / Container Registries | `container.repository.cloudera.com`, `quay.io`, `gcr.io`, `docker.io`, `mcr.microsoft.com` |
| AWS S3 (images & artifacts) | `*.s3.amazonaws.com`, `*.s3.us-west-2.amazonaws.com`, `*.s3.eu-west-1.amazonaws.com` |
| AKS | `login.microsoftonline.com`, `packages.microsoft.com`, `acs-mirror.azureedge.net`, `packages.aks.azure.com` |
| Azure Policy & Monitoring | `data.policy.core.windows.net`, `*.ods.opinsights.azure.com`, `*.oms.opinsights.azure.com` |
| DigiCert (TLS) | `www.digicert.com`, `cacerts.digicert.com` |
| Package Repos | `pypi.org`, `apt.releases.hashicorp.com`, `*.snapcraft.io` |
| NVIDIA GPU (AKS) | `nvidia.github.io`, `us.download.nvidia.com` |
| GitHub / Microsoft Tools | `github.com`, `raw.githubusercontent.com`, `objects.githubusercontent.com` |

### Application Rules (HTTP — port 80)

| Category | Endpoints |
|----------|-----------|
| Ubuntu package mirrors (AKS) | `security.ubuntu.com`, `azure.archive.ubuntu.com`, `changelogs.ubuntu.com`, `archive.ubuntu.com` |

### Network Rules (TCP 443)

Allows direct TCP connectivity to CDP Control Plane IP ranges:

| Region | IP Ranges |
|--------|-----------|
| US | `35.80.24.128/27`, `35.166.86.177/32`, `52.36.110.208/32`, `52.40.165.49/32` |
| EU | `3.65.246.128/27` |
| AP | `3.26.127.64/27` |

> The default rules reflect Cloudera's published network requirements as of mid-2025. Consult the [Cloudera documentation](https://docs.cloudera.com) for the latest requirements for your CDP version and region.

## Notes

- **Route table association:** This module looks up each subnet by its resource ID and patches its **existing** route table with a default internet route. The subnets must already have route tables associated before applying this module.
- **AzureFirewallSubnet:** The subnet provided via `firewall_subnet_id` must be named exactly `AzureFirewallSubnet` — this is an Azure platform requirement.
- **Rule customization:** `fw_app_rules` and `fw_net_rules` have sensible defaults but are fully overridable. Pass custom values to restrict or extend the rule sets for your environment.
- **CDP region selection:** The default rules include endpoints for all three CDP regions (US, EU, AP). If your deployment targets a single region, you may override the variables to include only the relevant endpoints.