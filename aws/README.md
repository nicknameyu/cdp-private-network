# CDP Private Network — AWS Terraform

This Terraform module provisions a complete **private network infrastructure on AWS** for deploying [Cloudera Data Platform (CDP)](https://docs.cloudera.com/cdp-public-cloud/cloud/overview/topics/cdp-overview.html) in a semi-private or fully-private configuration. It covers VPC topology, firewall rules, DNS, IAM prerequisites, KMS encryption, and jump servers.

---

## Architecture Overview

The module creates two interconnected VPCs joined by a Transit Gateway:

```
Internet
    │
   IGW
    │
[ Core VPC ]  ──── Transit Gateway ──── [ CDP VPC ]
  ├── Public Subnets (3 AZs, ELB-tagged)        ├── Private Subnets (3 AZs, internal-ELB-tagged)
  ├── NAT Subnet                                 └── Route53 Inbound DNS Resolver
  ├── Firewall Subnet (AWS Network Firewall)
  └── Core/Private Subnets
        └── Jump Server (Ubuntu + BIND9 DNS)
```

| Component | Description |
|---|---|
| **Core VPC** | Hosts the NAT gateway, AWS Network Firewall, and a Linux jump server running BIND9 for DNS forwarding |
| **CDP VPC** | Hosts CDP workloads in private subnets; uses a Route 53 inbound resolver for DNS |
| **Transit Gateway** | Connects Core and CDP VPCs; DNS support intentionally disabled (custom DNS handles resolution) |
| **AWS Network Firewall** | Domain-based egress allowlisting for all CDP outbound traffic |
| **S3 Gateway Endpoint** | Keeps S3 traffic off the public internet |

---

## Prerequisites

- Terraform `>= 1.0`
- AWS Provider `5.35.0` (pinned in `provider.tf`)
- AWS credentials configured with sufficient permissions to create VPCs, IAM roles, KMS keys, EC2 instances, and Network Firewall resources
- An SSH key pair on the machine running Terraform (default: `~/.ssh/id_rsa` / `~/.ssh/id_rsa.pub`)

---

## Quick Start

```bash
# 1. Clone the repo
git clone https://github.com/nicknameyu/cdp-private-network.git
cd cdp-private-network/aws

# 2. Create your tfvars file
cp terraform.tfvars.example.md terraform.tfvars
# Edit terraform.tfvars with your values (at minimum, set `owner`)

# 3. Initialize and apply
terraform init
terraform apply
```

---

## Input Variables

### Required

| Variable | Type | Description |
|---|---|---|
| `owner` | `string` | Owner name; used as a prefix for all created resources |

### Networking

| Variable | Type | Default | Description |
|---|---|---|---|
| `region` | `string` | `us-west-2` | AWS region |
| `core_vpc` | `object` | `{cidr="10.3.0.0/16", name=""}` | Core VPC CIDR and name. Minimum **/26** required |
| `cdp_vpc` | `object` | `{cidr="10.4.0.0/16", name=""}` | CDP VPC CIDR and name. Minimum **/22** required |
| `tgw_name` | `string` | `""` | Transit Gateway name (defaults to `<owner>_tgw`) |
| `igw_name` | `string` | `""` | Internet Gateway name |
| `natgw_name` | `string` | `""` | NAT Gateway name |
| `custom_dns` | `bool` | `true` | Use custom DNS (BIND9) in CDP VPC |

### Firewall

| Variable | Type | Default | Description |
|---|---|---|---|
| `fw_name` | `string` | `""` | Firewall name (defaults to `<owner>-firewall`) |
| `firewall_control` | `bool` | `true` | Route CDP VPC internet traffic through the firewall |
| `public_snet_to_firewall` | `bool` | `true` | Route public subnet traffic through the firewall |
| `fw_domain_ep` | `list(string)` | *(see variables.tf)* | HTTPS/TLS domain allowlist for the firewall |
| `fw_http_ep` | `list(string)` | Ubuntu update domains | HTTP domain allowlist for the firewall |

### IAM & Security

| Variable | Type | Default | Description |
|---|---|---|---|
| `cross_account_role` | `string` | `null` | Existing cross-account role name to import; if `null`, a new role is created |
| `cdp_xaccount_account_id` | `string` | `387553343826` | CDP control plane AWS account ID to trust in the cross-account role |
| `cdp_xaccount_external_id` | `string` | `null` | External ID for the cross-account trust relationship |
| `aws_sso_user_arn_keyword` | `string` | `cldr_poweruser` | Keyword to match SSO user ARNs in the cross-account trust policy |
| `default_permission` | `bool` | `true` | Use default (broad) IAM permissions; set to `false` for reduced permissions |
| `customer_xa_policy` | `list(string)` | `null` | Paths to additional customer-provided IAM policy JSON files |

### KMS (Customer-Managed Keys)

| Variable | Type | Default | Description |
|---|---|---|---|
| `enable_cmk` | `bool` | `true` | Create and configure a KMS CMK for CDP Liftie clusters |
| `cmk_key_name` | `string` | `null` | KMS key alias (defaults to `<owner>-cdp-key`) |

### Data Services

| Variable | Type | Default | Description |
|---|---|---|---|
| `enable_de` | `bool` | `true` | Enable IAM permissions for Data Engineering |
| `enable_df` | `bool` | `true` | Enable IAM permissions for DataFlow |
| `enable_dw` | `bool` | `true` | Enable IAM permissions for Data Warehouse |
| `enable_ai` | `bool` | `true` | Enable IAM permissions for AI |
| `create_eks_role` | `bool` | `false` | Create CloudFormation stack for EKS role/instance profile (reduced permissions mode) |

### Compute

| Variable | Type | Default | Description |
|---|---|---|---|
| `cdp_bucket_name` | `string` | `null` | CDP S3 bucket name (defaults to `<owner>-cdp-poc-bucket`) |
| `ssh_key` | `object` | `{public_key_path="~/.ssh/id_rsa.pub", private_rsa_key_path="~/.ssh/id_rsa"}` | SSH key paths for EC2 provisioning |
| `create_windows_jumpserver` | `bool` | `false` | Create a Windows Server 2022 jump server in the public subnet |
| `tags` | `map(string)` | `null` | Additional tags applied to all resources |

---

## Outputs

| Output | Description |
|---|---|
| `core_jump_public_ip` | Public IP of the Core VPC jump server |
| `core_jump_private_ip` | Private IP of the Core VPC jump server |
| `cdp_jump_private_ip` | Private IP of the CDP VPC jump server |
| `cdp_dns_resolver_endpoint` | IP addresses of the Route53 inbound resolver in the CDP VPC |
| `storage_locations` | S3 storage locations created for CDP |
| `cdp_roles` | IAM role names and instance profiles for CDP |
| `kms_key_arn` | ARN of the KMS CMK (if `enable_cmk = true`) |
| `win_jumpserver` | Windows jump server public IP, username, and decrypted password (if enabled) |

---

## Module Structure

```
aws/
├── provider.tf              # AWS provider and Terraform version constraints
├── variables.tf             # All input variables and local CIDR calculations
├── network.tf               # VPCs, subnets, IGW, NAT GW, Transit Gateway
├── routing.tf               # Route tables and routes
├── firewall.tf              # AWS Network Firewall, rule groups, and policy
├── sg.tf                    # Security groups
├── security-groups/         # Security group submodule
├── dnsresolver.tf           # Route53 inbound resolver in CDP VPC
├── dns-setup.tf             # DNS configuration
├── s3endpoint.tf            # S3 VPC gateway endpoint
├── servers.tf               # Jump servers (Linux + optional Windows)
├── pre-requisite.tf         # CDP environment prerequisites (S3, IAM roles/policies)
├── xaccount-role.tf         # CDP cross-account IAM role
├── cmk-prerequisites.tf     # KMS CMK for CDP encryption
├── data-service-permissions.tf  # Per-service IAM permissions (DE, DF, DW, AI)
├── conf/
│   ├── named.conf           # BIND9 configuration (templated with region/resolver IP)
│   └── named.conf.options   # BIND9 options
└── cf/
    └── aws-liftie-role-pair.yaml  # CloudFormation template for EKS Liftie roles
```

---

## DNS Architecture

Custom DNS resolution is handled by a two-tier setup:

1. **Core VPC jump server** runs **BIND9**, configured to forward `.amazonaws.com` and AWS service domains to the Route 53 resolver IP in the CDP VPC. This file is dynamically generated at apply time using the resolver's IP.
2. **CDP VPC** has a **Route 53 inbound resolver endpoint** deployed across all three private subnets, enabling the BIND9 forwarder to resolve private AWS DNS names correctly.

This setup allows CDP workloads in the private CDP VPC to resolve VPC-private DNS names (e.g., VPC endpoint DNS, RDS, EKS) without enabling DNS support on the Transit Gateway.

---

## Firewall Egress Allowlist

The AWS Network Firewall is configured with a domain-based **TLS SNI allowlist** covering:

- Cloudera CCMv2 endpoints (US, EU, AP control planes)
- Cloudera Databus and control plane APIs
- Container registries: `quay.io`, `docker.io`, `gcr.io`, `container.repository.cloudera.com`
- AWS service endpoints: ECR, EKS, EFS, ELB, STS, RDS, CloudFormation, Autoscaling
- CDP Liftie/NiFi operator endpoints
- Ubuntu package mirrors (HTTP allowlist)

Regional AWS endpoints (e.g., `eks.us-west-2.amazonaws.com`) are computed dynamically from the `region` variable. The S3 endpoint is handled via a VPC gateway endpoint rather than firewall rules.

---

## External Modules Used

| Module | Source |
|---|---|
| CDP env prerequisites | `github.com/nicknameyu/cdp-prerequisite-module/aws/env-prerequisites` |
| Cross-account role | `github.com/nicknameyu/cdp-prerequisite-module/aws/xaccount-role` |
| CMK prerequisites | `github.com/nicknameyu/cdp-prerequisite-module/aws/cmk-prerequisites` |

---

## Notes

- The `owner` variable is used as a prefix for nearly all resource names. Use a short, unique value (e.g., your username).
- Subnet CIDRs are calculated automatically from the VPC CIDR using `cidrsubnet()`. The Core VPC requires at minimum a `/26`; the CDP VPC requires at minimum a `/22`.
- Setting `firewall_control = false` or `public_snet_to_firewall = false` bypasses firewall routing for testing. Do not use in production.
- Windows jump server password is decrypted in Terraform state using your RSA private key. Treat the state file as sensitive.
- The `cdp_xaccount_account_id` defaults to the Cloudera NA Sandbox tenant. Update this to your CDP tenant's AWS account ID.