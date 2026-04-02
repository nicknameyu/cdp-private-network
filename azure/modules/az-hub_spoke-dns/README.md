# az-hub_spoke-dns

A Terraform module that provisions a complete hub-and-spoke DNS architecture on Azure for CDP (Cloudera Data Platform) private network deployments. It combines a BIND9-based DNS server in the hub VNet with an Azure Private DNS Resolver in the spoke VNet, wiring them together via BIND9 conditional forwarding so that private DNS zones (AKS, PostgreSQL, MySQL) resolve correctly across the network boundary.

## Architecture Overview

```
┌─────────────────────────────────────────┐     ┌───────────────────────────────────────────────┐
│              Hub VNet                   │     │                  Spoke VNet                   │
│                                         │     │                                               │
│  ┌─────────────────────────────────┐    │     │  ┌────────────────────────────────────────┐   │
│  │   DNS Server (Ubuntu + BIND9)   │    │     │  │  Azure Private DNS Resolver            │   │
│  │                                 │◄───┼─────┼──│  - Inbound Endpoint (dynamic IP)       │   │
│  │  Conditional forwarders:        │    │     │  │  - Subnet: dns_resolver_inbound        │   │
│  │  - AKS private DNS zone    ─────┼────┼─────┼─►│                                        │   │
│  │  - PostgreSQL private DNS  ─────┼────┼─────┼─►│  Resolves Azure Private Link zones     │   │
│  │  - MySQL private DNS       ─────┼────┼─────┼─►│  for AKS, PostgreSQL, MySQL            │   │
│  │                                 │    │     │  └────────────────────────────────────────┘   │
│  └─────────────────────────────────┘    │     │                                               │
│  DNS Servers setting: Azure Default     │     │  DNS Servers setting: DNS Server private IP   │
└─────────────────────────────────────────┘     └───────────────────────────────────────────────┘
```

**DNS resolution flow for spoke workloads:**

1. A pod or VM in the spoke VNet queries the custom DNS server (BIND9 in the hub).
2. BIND9 checks its conditional forwarders. If the query matches an AKS, PostgreSQL, or MySQL private DNS zone, it forwards to the Private DNS Resolver inbound endpoint IP.
3. The Private DNS Resolver resolves the name via the Azure Private DNS zones linked to the spoke VNet.
4. All other queries fall through to BIND9's upstream resolvers (configured in `named.conf.options`).

## What This Module Creates

| Resource | Description |
|---|---|
| `module.dns_server` | Ubuntu VM (via `az-ubuntu_vm` sub-module) with a public IP and NSG, running BIND9 |
| `azurerm_virtual_network_dns_servers.hub` | (Optional) Sets the hub VNet custom DNS to the BIND9 server private IP |
| `azurerm_subnet.dns_resolver_inbound` | Dedicated subnet in the spoke VNet, delegated to `Microsoft.Network/dnsResolvers` |
| `azurerm_private_dns_resolver` | Azure Private DNS Resolver attached to the spoke VNet |
| `azurerm_private_dns_resolver_inbound_endpoint` | Inbound endpoint (dynamic IP) used as the BIND9 conditional forward target |
| `azurerm_virtual_network_dns_servers.spoke` | (Optional) Sets the spoke VNet custom DNS to the BIND9 server private IP |
| `null_resource.private_key` | Uploads the SSH private key to the DNS server via remote-exec |
| `null_resource.conf` | Uploads rendered BIND9 config files and runs `bootstrap.sh` via remote-exec |

## Prerequisites

- Terraform `>= 1.0`
- AzureRM provider configured with sufficient permissions to manage VNets, subnets, VMs, DNS resolvers, and resource groups
- An existing hub VNet with a subnet to host the DNS server
- An existing spoke VNet
- An SSH key pair accessible from the machine running Terraform
- Network connectivity (public IP or bastion) from the Terraform host to the DNS server VM for provisioning

## Usage

```hcl
module "hub_spoke_dns" {
  source = "./modules/az-hub_spoke-dns"

  location = "eastus"
  tags     = { environment = "dev", project = "cdp" }

  # Hub VNet — derive from the DNS server subnet ID
  dns_server_subnet_id    = "/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Network/virtualNetworks/<hub-vnet>/subnets/<dns-subnet>"
  hub_vnet_default_dns    = true   # keep hub VNet on Azure Default DNS

  # Spoke VNet
  spoke_vnet_id              = "/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Network/virtualNetworks/<spoke-vnet>"
  spoke_vnet_default_dns     = false  # point spoke VNet at the BIND9 server
  dns_resolver_subnet_prefix = "10.1.4.0/28"
  private_dns_resolver_name  = "cdp-dns-resolver"

  # DNS server VM
  dns_server_resource_group_name   = "rg-dns-server"
  create_dns_server_resource_group = true
  dns_server_name                  = "cdp-dns-server"
  admin_username                   = "ubuntu"
  ssh_pub_key                      = "~/.ssh/id_rsa.pub"
  ssh_private_key                  = "~/.ssh/id_rsa"

  # BIND9 conditional forward zones (Azure Private DNS zone names)
  conditional_forward_zones = {
    aks   = "privatelink.eastus.azmk8s.io"
    pgdb  = "privatelink.postgres.database.azure.com"
    mysql = "privatelink.mysql.database.azure.com"
  }
}
```

## Input Variables

### General

| Name | Type | Default | Description |
|---|---|---|---|
| `location` | `string` | `"westus2"` | Azure region for all resources |
| `tags` | `map(string)` | `null` | Tags applied to all taggable resources |

### Hub VNet

| Name | Type | Default | Description |
|---|---|---|---|
| `hub_vnet_default_dns` | `bool` | `true` | When `true`, the hub VNet keeps Azure Default DNS. Set to `false` to point it at the BIND9 server. |

### Spoke VNet

| Name | Type | Default | Description |
|---|---|---|---|
| `spoke_vnet_id` | `string` | — | Resource ID of the spoke VNet |
| `spoke_vnet_default_dns` | `bool` | `false` | When `false`, the spoke VNet custom DNS is set to the BIND9 server private IP |
| `dns_resolver_subnet_prefix` | `string` | — | CIDR prefix for the `dns_resolver_inbound` subnet created inside the spoke VNet. Must be at least `/28`. |
| `private_dns_resolver_name` | `string` | `""` | Name for the Private DNS Resolver. Defaults to `"dns-resolver"` if empty. |

### DNS Server VM

| Name | Type | Default | Description |
|---|---|---|---|
| `dns_server_resource_group_name` | `string` | — | Resource group for the DNS server VM |
| `create_dns_server_resource_group` | `bool` | `false` | Whether to create the resource group |
| `dns_server_name` | `string` | `"dns_server"` | Name of the DNS server VM |
| `dns_server_subnet_id` | `string` | — | Subnet ID in the **hub** VNet where the DNS server VM will be placed. The hub VNet ID is derived from this value. |
| `admin_username` | `string` | `"ubuntu"` | SSH admin username for the VM |
| `ssh_pub_key` | `string` | `"~/.ssh/id_rsa.pub"` | Path to the SSH public key installed on the VM |
| `ssh_private_key` | `string` | `"~/.ssh/id_rsa"` | Path to the SSH private key used for remote provisioning. Set to `""` to skip private key deployment. |
| `bootstrap_script` | `string` | `""` | Path to an optional extra bootstrap script. Defaults to no extra bootstrapping. |

### BIND9 Conditional Forwarding

| Name | Type | Default | Description |
|---|---|---|---|
| `conditional_forward_zones` | `object({ aks=string, pgdb=string, mysql=string })` | — | Azure Private DNS zone names for AKS, PostgreSQL, and MySQL. Queries matching these zones are forwarded to the Private DNS Resolver inbound endpoint. |

## Outputs

| Name | Description |
|---|---|
| `dns-server_ip` | Object with `public` and `private` IP addresses of the BIND9 DNS server VM |
| `dns_resolver_inbound_ip` | Private IP of the Azure Private DNS Resolver inbound endpoint in the spoke VNet |

## DNS Server Bootstrapping

VM provisioning is a two-stage process:

**Stage 1 — Cloud-init (`dns_vm_user_data.sh`):** Runs automatically at VM first boot. Performs `apt update/upgrade`, installs `bind9` and `dnsutils`, and installs the Azure CLI with the AKS CLI extension.

**Stage 2 — Terraform remote-exec (`bootstrap.sh`):** After the VM is reachable, Terraform SSHes in and:
1. Uploads the rendered `named.conf` (with interpolated zone names and DNS resolver IP) and `named.conf.options` to `/tmp/`.
2. Runs `bootstrap.sh`, which copies the configs to `/etc/bind/`, sets correct ownership (`root:bind`) and permissions (`644`), then restarts `bind9.service`.

The `null_resource.conf` trigger is a hash of all three inputs (both config files and the bootstrap script), so re-applying after any config change will re-push and restart BIND9 automatically.

## Notes and Considerations

- **Hub VNet ID derivation:** The hub VNet resource ID is parsed from `dns_server_subnet_id` by splitting on `/` and rejoining the first nine segments. Ensure the subnet ID is a fully qualified Azure resource ID.
- **Spoke VNet delegation:** The `dns_resolver_inbound` subnet is delegated to `Microsoft.Network/dnsResolvers` with the join action explicitly set. This prevents Terraform drift on subsequent applies (Azure adds the action by default if omitted).
- **Service endpoints:** The DNS resolver inbound subnet is provisioned with service endpoints for `Microsoft.Sql`, `Microsoft.Storage`, and `Microsoft.KeyVault`.
- **Public IP on DNS server:** The DNS server VM is created with a public IP to allow Terraform remote-exec provisioning. Ensure your NSG or firewall allows SSH (port 22) from the Terraform execution host.
- **SSH private key on VM:** The module copies your SSH private key to `~/.ssh/id_rsa` on the DNS server. This supports scenarios where the DNS server needs to SSH to other resources (e.g., AKS nodes). Set `ssh_private_key = ""` to skip this step.
- **Conditional forward zone names:** Use the exact Azure Private DNS zone names for your region and service, e.g. `privatelink.eastus.azmk8s.io` for AKS in East US.

## File Structure

```
az-hub_spoke-dns/
├── dns_server.tf           # DNS server VM module call and BIND9 remote provisioning
├── hub_vnet.tf             # Optional hub VNet custom DNS configuration
├── spoke_vnet.tf           # Private DNS Resolver, inbound endpoint, spoke VNet DNS config
├── variables.tf            # All input variable declarations
├── conf/
│   ├── named.conf          # BIND9 main config template (conditional forwarders injected)
│   └── named.conf.options  # BIND9 options config (upstreams, ACLs, etc.)
└── scripts/
    ├── dns_vm_user_data.sh # Cloud-init: installs BIND9, dnsutils, Azure CLI
    └── bootstrap.sh        # Remote-exec: deploys BIND9 config and restarts service
```