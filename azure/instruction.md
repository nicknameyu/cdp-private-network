# Terraform Configuration for Azure Resources

This repository contains Terraform configurations to deploy and manage Azure resources. The configurations include creating resource groups, virtual networks (VNETs), subnets, firewall rules, and various infrastructure components required for a complete setup.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Usage](#usage)
3. [Variables](#variables)
   - [Universal Variables](#universal-variables)
   - [Network Variables](#network-variables)
   - [Firewall Rules](#firewall-rules)
   - [Prerequisites](#prerequisites)
   - [Servers](#servers)
   - [Miscellaneous](#miscellaneous)


## Prerequisites
- [Terraform](https://www.terraform.io/downloads.html) 1.5.0 or later
- Azure account with appropriate permissions
- SSH key pair for authentication

## Usage
1. Clone the repository:
    ```bash
    git clone git@github.infra.cloudera.com:Cloud-Solution-Architects/cdp-pc-pvt-nw-lab.git
    ```

2. Initialize Terraform:
    ```bash
    terraform init
    ```

3. Review the variables in `variables.tf` and polulate `terraform.tfvars` file as necessary.

4. Apply the configuration:
    ```bash
    terraform apply
    ```

5. Confirm the apply action with `yes`.

## Variables

### Universal Variables

- **owner** (string)
  - This is used as the prefix of the default value of the name of many resources.

- **resource_groups** (object)
  - Description: The template will create 4 resource groups to hold resources: the network resource group, the prerequisite resource group, the CDP environment resource group, and the jump server resource group.
  - The default value is `null`. When set to `null`, default values with prefix of `$owner` will be created. 
  - Structure:
    ```hcl
    {
      network_rg      = string
      prerequisite_rg = string
      cdp_rg          = string
      vms_rg          = string
    }
    ```

- **tags** (map(string))
  - Description: Tags to be applied to the resources.

- **location** (string)
  - Description: Azure region where the resources will be created.
  - Default: `westus`

### Network Variables

- **hub_cidr** (string)
  - Description: The CIDR range of HUB VNET.
  - Default: `10.128.0.0/16`
  - Validation: Minimum /25 CIDR is required for HUB VNET.

- **cdp_cidr** (string)
  - Description: The CIDR range of CDP VNET.
  - Default: `10.100.0.0/16`
  - Validation: Minimum /20 CIDR is required for CDP VNET.

- **hub_vnet_name** (string)
  - Description: The name of HUB VNET. When set to null, default to `$owner-hub-vnet`

- **cdp_vnet_name** (string)
  - Description: The name of CDP VNET. When set to null, default to `$owner-cdp-vnet`

### Firewall Rules

- **fw_app_rules** (map)
  - Description: Application rules for the firewall.
  - Structure:
    ```hcl
    {
      https_rules = {
        target_fqdns = [ ... ]
        type = "Https"
        port = "443"
      }
      http_rules = {
        target_fqdns = [ ... ]
        type = "Http"
        port = "80"
      }
    }
    ```

- **fw_net_rules** (map)
  - Description: Network rules for the firewall.
  - Structure:
    ```hcl
    {
      https_rules = {
        ip_prefix = [ ... ]
        destination_ports = ["443"]
        protocols = ["TCP"]
      }
    }
    ```

### Prerequisites

- **managed_id** (object)
  - Description: The names of the required managed identities.
  - When set to `null`, default values with prefix `$owner` will be created.
  - Structure:
    ```hcl
    {
      assumer    = string
      dataaccess = string
      logger     = string
      ranger     = string
      raz        = string
    }
    ```

- **cdp_storage** (string)
  - Description: The name of the ADLS storage account.

- **cdp_file_storage** (string)
  - Description: The name of the file storage for Machine Learning.

- **custom_role_names** (object)
  - Description: Custom role names.
  - When set to `null`, default values with prefix `$owner` will be created.
  - Structure:
    ```hcl
    {
      dw                   = string
      liftie               = string
      env_single_rg_svc_ep = string
      env_single_rg_pvt_ep = string
      cmk                  = string
      mkt_img              = string
    }
    ```

### Servers

- **winclient_vm_name** (string)
  - Description: The name of the Windows 11 VM. 
  - When set to `null`, default values with prefix `$owner` will be created.

- **hub_jump_server_name** (string)
  - Description: The name of the jump server in the HUB VNET.
  - When set to `null`, default values with prefix `$owner` will be created.

- **cdp_jump_server_name** (string)
  - Description: The name of the jump server in the CDP VNET.
  - When set to `null`, default values with prefix `$owner` will be created.

- **admin_username** (string)
  - Description: The administrator's username for the jump servers.
  - Default to `null`. When set to null, will use the `$owner` as the administrator name.

- **password** (string)
  - Description: The password for the Windows 11 servers.

### Miscellaneous

- **spn_object_id** (string)
  - Description: The object ID of the SPN.

- **spn_permision_contributor** (bool)
  - Description: Controls the permission of SPN on the subscription. If true, grants contributor to SPN; if false, grants minimum permission to SPN.
  - Default: `false`

- **kv_name** (string)
  - Description: The name of the Key Vault.
  - Default: `""`

- **public_key** (string)
  - Description: Path for the SSH public key to be added to the jump servers.
  - Default: `~/.ssh/id_rsa.pub`

- **private_key** (string)
  - Description: Path for the SSH private key used to bootstrap servers.
  - Default: `~/.ssh/id_rsa`

- **custom_dns** (bool)
  - Description: Controls the DNS setting on the VNETs. When true, the DNS setting points to a custom DNS server. When false, uses Azure Default DNS.
  - Default: `true`


---

Adjust the variables in the `variables.tf` file to match your desired configuration. For more details on each variable, refer to the inline comments and descriptions within the file.
