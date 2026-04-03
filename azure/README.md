# CDP Private Network – Azure Terraform

This Terraform configuration provisions a **fully private, hub-and-spoke network environment** on Azure for [Cloudera Data Platform (CDP)](https://www.cloudera.com/products/cloudera-data-platform.html). It sets up all networking, security, DNS, storage, managed identities, firewall rules, and optional jump servers required to run CDP in a private network topology.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│  Hub VNET  (default: 10.128.0.0/16)                     │
│  ┌───────────────────┐  ┌──────────────────────────┐    │
│  │ Azure Firewall     │  │ DNS Server (Linux VM)    │    │
│  │ (AzureFirewallSub) │  │ (pub_subnet_1)           │    │
│  └───────────────────┘  └──────────────────────────┘    │
│  ┌─────────────────────────────────────────────────┐     │
│  │ Windows Jump Client (optional, pub_subnet_1)    │     │
│  └─────────────────────────────────────────────────┘     │
└──────────────────────┬──────────────────────────────────┘
                       │ VNET Peering
┌──────────────────────▼──────────────────────────────────┐
│  CDP (Spoke) VNET  (default: 10.100.0.0/16)             │
│  ┌──────────────────────────────────────────────────┐   │
│  │ Private Subnets (pvt_subnet_1 … pvt_subnet_8)    │   │
│  │ PostgreSQL Flexible Server Delegated Subnet      │   │
│  │ DNS Resolver Inbound Endpoint                    │   │
│  └──────────────────────────────────────────────────┘   │
│  ┌────────────────────────────┐                         │
│  │ CDP Jump Server (optional) │                         │
│  └────────────────────────────┘                         │
└─────────────────────────────────────────────────────────┘
```

All egress traffic from the CDP VNET is routed through the Azure Firewall in the Hub VNET. Private DNS zones resolve Azure PaaS services internally, and a custom BIND DNS server handles conditional forwarding.

---

## Prerequisites

- Terraform `>= 1.0`
- AzureRM provider `>= 4.0.1`
- An existing Azure subscription
- An **Azure AD Application Registration** (Service Principal) whose **Enterprise Application Object ID** is known
- SSH key pair available locally (default paths: `~/.ssh/id_rsa` and `~/.ssh/id_rsa.pub`)
- Azure CLI authenticated (`az login`) or a service principal configured via environment variables

---

## Modules Used

| Module | Source | Purpose |
|--------|--------|---------|
| `hub_vnet` | `./modules/az-vnet` | Hub VNET with public subnets and Azure Firewall subnet |
| `spoke_vnet` | `./modules/az-vnet` | CDP (spoke) VNET with private subnets and PostgreSQL delegated subnet |
| `firewall` | `./modules/az-firewall` | Azure Firewall with application and network rules for CDP egress |
| `hub_spoke_dns` | `./modules/az-hub_spoke-dns` | Custom BIND DNS server + Azure Private DNS Resolver for hub-spoke DNS forwarding |
| `dns_zone` | `./modules/az-private_dns_zones` | Private DNS zones for AKS, PostgreSQL, MySQL, and other Azure PaaS services |
| `env-prerequisite` | `github.com/nicknameyu/cdp-prerequisite-module//azure/env-prerequisites` | CDP managed identities and ADLS Gen2 storage account |
| `nfs-prerequisite` | `github.com/nicknameyu/cdp-prerequisite-module//azure/nfs-prerequisites` | Azure Files NFS share for CML |
| `cdp_jump_server` | `./modules/az-ubuntu_vm` | Optional Linux jump server in the CDP VNET |
| `Windows` | `./modules/az-win11` | Optional Windows 11 jump client in the Hub VNET |

---

## Resource Groups

The template creates four resource groups (all prefixed with `var.owner` by default):

| Resource Group Variable | Default Name | Contents |
|-------------------------|--------------|----------|
| `network_rg` | `<owner>-network` | Hub and CDP VNETs, Firewall, peering, route tables |
| `prerequisite_rg` | `<owner>-cdp-prerequisite` | Managed identities, ADLS storage, NFS share |
| `cdp_rg` | `<owner>-cdp-env` | CDP environment resource group (used by CDP control plane) |
| `vms_rg` | `<owner>-vms` | DNS server VM, jump servers |

Custom names can be supplied via the `resource_groups` variable.

---

## Usage

### 1. Clone the repository

```bash
git clone https://github.com/nicknameyu/cdp-private-network.git
cd cdp-private-network/azure
```

### 2. Create a `terraform.tfvars` file

Copy the example and fill in your values:

```bash
cp terraform.tfvars.example.md terraform.tfvars
```

Minimum required values:

```hcl
owner            = "yourname"
subscription_id  = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
tenant_id        = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
spn_object_id    = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"  # Enterprise Application Object ID
cdp_storage      = "yourcdpstorage"
cdp_file_storage = "yourcdpfilestorage"
kv_name          = "yourkeyvaultname"
```

### 3. Initialize and apply

```bash
terraform init
terraform plan
terraform apply
```

---

## Input Variables

### Required

| Variable | Type | Description |
|----------|------|-------------|
| `owner` | `string` | Prefix used for resource naming throughout the deployment |
| `subscription_id` | `string` | Azure Subscription ID (required by AzureRM >= 4.0) |
| `tenant_id` | `string` | Azure AD Tenant ID |
| `spn_object_id` | `string` | Object ID of the Enterprise Application (not the App Registration) |
| `cdp_storage` | `string` | Name of the ADLS Gen2 storage account for CDP |
| `cdp_file_storage` | `string` | Name of the Azure Files storage account for CML NFS |

### Networking

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `hub_cidr` | `string` | `10.128.0.0/16` | CIDR for the Hub VNET (minimum /20) |
| `cdp_cidr` | `string` | `10.100.0.0/16` | CIDR for the CDP (spoke) VNET (minimum /20) |
| `hub_vnet_name` | `string` | `<owner>-hub-vnet` | Override name for the Hub VNET |
| `cdp_vnet_name` | `string` | `<owner>-cdp-vnet` | Override name for the CDP VNET |
| `firewall_name` | `string` | `<owner>-fw` | Override name for the Azure Firewall |
| `dns_resolver_name` | `string` | `<owner>-dns-resolver` | Override name for the Private DNS Resolver |
| `location` | `string` | `westus` | Azure region for all resources |
| `public_env` | `bool` | `false` | When `false`, default route on CDP subnets points to the firewall |
| `custom_dns` | `bool` | `true` | When `true`, VNETs use the custom BIND DNS server instead of Azure default DNS |
| `dns_zone_subscription_id` | `string` | `null` | Subscription ID for private DNS zones if managed separately |

### Servers / Jump Hosts

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `create_win_client` | `bool` | `false` | Create a Windows 11 jump client in the Hub VNET |
| `create_cdp_jump_server` | `bool` | `false` | Create a Linux jump server in the CDP VNET |
| `admin_username` | `string` | `<owner>` | Administrator username for VMs |
| `password` | `string` | `Passw0rd` | Password for the Windows client |
| `public_key` | `string` | `~/.ssh/id_rsa.pub` | Path to SSH public key for jump servers |
| `private_key` | `string` | `~/.ssh/id_rsa` | Path to SSH private key (used for bootstrapping) |
| `hub_jump_server_name` | `string` | `<owner>HubJump` | Override name for the Hub jump server (max 14 chars) |
| `cdp_jump_server_name` | `string` | `<owner>CdpJump` | Override name for the CDP jump server (max 14 chars) |
| `winclient_vm_name` | `string` | `null` | Override name for the Windows VM (max 14 chars) |

### Key Vault & CMK

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `kv_name` | `string` | `""` | Name of the Azure Key Vault for Customer Managed Keys |
| `kv_rbac` | `bool` | `true` | Use RBAC (`true`) or Access Policy (`false`) for Key Vault authorization |

### IAM & Roles

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `spn_permision_contributor` | `bool` | `false` | Grant Contributor to the SPN (`true`) or minimum required permissions (`false`) |
| `managed_id` | `object` | `null` | Override names for CDP managed identities (assumer, dataaccess, logger, ranger, raz) |
| `custom_role_names` | `object` | `null` | Override names for custom IAM roles (dw, liftie, datalake, cmk, mkt_img, dns_zone) |
| `enable_dw` | `bool` | `true` | Enable Data Warehouse custom role permissions |
| `enable_liftie` | `bool` | `true` | Enable Liftie (AKS) custom role permissions |
| `enable_de` | `bool` | `true` | Enable Data Engineering custom role permissions |
| `ds_custom_role` | `string` | `null` | Custom role name for data services granted to managed identities |

### Storage

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `storage_account_tier` | `string` | `Standard` | CDP storage account performance tier |
| `storage_account_replication_type` | `string` | `LRS` | CDP storage replication type (LRS, GRS, ZRS, etc.) |

### Tags

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `tags` | `map(string)` | `null` | Tags applied to all resources |
| `resource_groups` | `object` | `null` | Override all four resource group names |

---

## Outputs

| Output | Description |
|--------|-------------|
| `storage_locations` | ADLS storage, log, backup, and NFS file share paths for CDP environment setup |
| `ssh_public_key` | Contents of the SSH public key (for use in CDP environment configuration) |
| `dns-server_pip` | IP address of the custom DNS server VM in the Hub VNET |
| `cdp-server_ip` | Private IP of the CDP jump server |
| `win-server_ip` | Public IP of the Windows jump client (or `null` if not created) |
| `private_dns_zones` | Map of private DNS zone resource IDs |

---

## Networking Details

### Subnets

**Hub VNET** — 8 public subnets (`pub_subnet_1` … `pub_subnet_8`) plus `AzureFirewallSubnet`

**CDP VNET** — 8 private subnets (`pvt_subnet_1` … `pvt_subnet_8`), a delegated subnet for PostgreSQL Flexible Server, and a DNS Resolver inbound endpoint subnet

### Firewall

An Azure Firewall is deployed in the Hub VNET. All traffic from the CDP subnets is routed through the firewall via UDRs. Application and network rules permit the outbound connectivity required by CDP (see `firewall-rules.tf` and the `az-firewall` module for the full rule set).

### DNS

A custom BIND DNS server runs on a Linux VM in `pub_subnet_1` of the Hub VNET and acts as the DNS server for both VNETs when `custom_dns = true`. An Azure Private DNS Resolver inbound endpoint is created in the CDP VNET. Conditional forwarding is configured for AKS, PostgreSQL, and MySQL private DNS zones.

Private DNS zones are created (optionally in a separate subscription) and linked to both VNETs.

---

## Tools

### `tools/remove_orphan_kubenet_routes.sh`

A helper script to clean up orphaned kubenet routes in the CDP VNET route table. This is useful after AKS clusters are deleted and their node-pool routes are left behind.

```bash
bash tools/remove_orphan_kubenet_routes.sh
```

---

## Notes

- **SPN Object ID**: Use the Object ID from **Enterprise Applications** in Azure AD, not the App Registration.
- **DNS zones in a separate subscription**: Set `dns_zone_subscription_id` to deploy private DNS zones into a centrally managed subscription. The secondary AzureRM provider alias handles this automatically.
- **Key Vault soft delete**: The provider is configured to purge soft-deleted Key Vaults on destroy and recover them if they exist, preventing naming conflicts during re-deployments.
- **Resource group deletion**: The provider allows deletion of non-empty resource groups (`prevent_deletion_if_contains_resources = false`).