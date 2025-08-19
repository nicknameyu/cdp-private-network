######### universal variables #########
variable "resource_groups" {
  description = "The template will create 4 resource groups to hold resources: the network resource group, the prerequisite resource group, the cdp environment resource group, and the jump server resource group. Default to null, and a list of default names with the $owner as the prefix will be created."
  type = object({
    network_rg      = string
    prerequisite_rg = string
    cdp_rg          = string
    vms_rg          = string
  })
  default = null
}
variable "tags" {
  description = "Tags to be applied to the resources."
  type = map(string)
  default = null
}

variable "location" {
  description = "Azure region where the resources will be created."
  type = string
  default = "westus"
}

############# Networks #############
variable "hub_cidr" {
  description = "The CIDR range of HUB VNET."
  default     = "10.128.0.0/16"
  validation {
    condition     = tonumber(split("/", var.hub_cidr)[1]) <= 20
    error_message = "A minimum /20 CIDR is required for HUB VNET."
  }
}
variable "cdp_cidr" {
  description = "The CIDR range of CDP VNET."
  default     = "10.100.0.0/16"
  validation {
    condition     = tonumber(split("/", var.cdp_cidr)[1]) <= 20
    error_message = "A minimum /20 CIDR is required for CDP VNET."
  }
}
variable "hub_vnet_name" {
  description = "The name of HUB VNET. Default to $owner-hub-vnet"
  default = null
  type = string
}
variable "cdp_vnet_name" {
  description = "The name of CDP VNET. Default to $owner-cdp-vnet"
  default = null
  type = string
}
locals {
  hub_vnet_masknum = tonumber(split("/", var.hub_cidr)[1])
  hub_subnets = {
    AzureFirewallSubnet = [cidrsubnet(var.hub_cidr, 26 - local.hub_vnet_masknum, 0 )]
    coresubnet          = [cidrsubnet(var.hub_cidr, 26 - local.hub_vnet_masknum, 1 )]
  }
  hub_pub_subnets = {
    pub_subnet_1        = [cidrsubnet(var.hub_cidr, 24 - local.hub_vnet_masknum, 1 )]
    pub_subnet_2        = [cidrsubnet(var.hub_cidr, 24 - local.hub_vnet_masknum, 2 )]
    pub_subnet_3        = [cidrsubnet(var.hub_cidr, 24 - local.hub_vnet_masknum, 3 )]
    pub_subnet_4        = [cidrsubnet(var.hub_cidr, 24 - local.hub_vnet_masknum, 4 )]
  }
  cdp_vnet_masknum = tonumber(split("/", var.cdp_cidr)[1])
  cdp_subnets = {
    subnet_26_1 = cidrsubnet(var.cdp_cidr, 26 - local.cdp_vnet_masknum, 1)
    subnet_25_1 = cidrsubnet(var.cdp_cidr, 25 - local.cdp_vnet_masknum, 1)
    subnet_24_1 = cidrsubnet(var.cdp_cidr, 24 - local.cdp_vnet_masknum, 1)
    subnet_23_1 = cidrsubnet(var.cdp_cidr, 23 - local.cdp_vnet_masknum, 1)
    subnet_22_1 = cidrsubnet(var.cdp_cidr, 22 - local.cdp_vnet_masknum, 1)
    subnet_21_1 = cidrsubnet(var.cdp_cidr, 21 - local.cdp_vnet_masknum, 1)
  }
  resolver_inbound_subnet_cidr = cidrsubnet(var.cdp_cidr, 28 - local.cdp_vnet_masknum, 0)
  pg_flx_subnet_cidr           = cidrsubnet(var.cdp_cidr, 28 - local.cdp_vnet_masknum, 1)
}

variable "firewall_name" {
  description = "The name for the Azure Firewall. Default to $owner-fw"
  type = string
  default = null
}

variable "dns_resolver_name" {
  description = "The name for the private DNS resolver on CDP VNET. Default to $owner-dns-resolver"
  default = null
  type = string
}
########### prerequisites #############
variable "managed_id" {
  description = "The name of the required managed identities. Default to null and a list of default names will be assigned."
  type = object({
    assumer    = string
    dataaccess = string
    logger     = string
    ranger     = string
    raz        = string
  })
  default = null
}

variable "cdp_storage" {
  type = string
  description = "The name of the ADLS storage account."
}
variable "cdp_file_storage" {
  description = "The name of the file storage that could be used in Machine Learning."
  type = string
}
variable "custom_role_names" {
  type = object({
    dw                   = string
    liftie               = string
    datalake             = string
    cmk                  = string
    mkt_img              = string                // new added for RHEL8 Azure Market Image
    dns_zone             = string
  })
  default = null
}

########### Servers ############
variable "create_win_client" {
  default = false
  type = bool
  description = "A switch to control whether to create windows client."
}
variable "winclient_vm_name" {
  description = "The name of the windows11 VM."
  type        = string
  default     = null
  validation {
    condition     = var.winclient_vm_name == null ? true : length(var.winclient_vm_name) < 15
    error_message = "Lenght of a VM name must be shorter than 15."
  }
}
variable "hub_jump_server_name" {
  description = "The name of the jump server sitting in hub VNET. Default to $ownerHubJump"
  type        = string
  default     = null
  validation {
    condition     = var.hub_jump_server_name == null ? true : length(var.hub_jump_server_name) < 15
    error_message = "Lenght of a VM name must be shorter than 15."
  }
}
variable "create_cdp_jump_server" {
  default = false
  type = bool
  description = "A switch to control whether to create a linux jump server in CDP VNET."
}
variable "cdp_jump_server_name" {
  description = " The name of the jump server sitting in cdp VNET. Default to $ownerCdpJump"
  type        = string
  default     = null
  validation {
    condition     = var.cdp_jump_server_name == null ? true : length(var.cdp_jump_server_name) < 15
    error_message = "Lenght of a VM name must be shorter than 15."
  }
}
variable "admin_username" {
  description = "The administrator's name for the jump servers. Default to $owner."
  type        = string
  default     = null
}
variable "password" {
  description = "The password of the Win Client"
  type        = string
  default     = "Passw0rd"
}

##################
variable "spn_object_id" {
  description = "The object ID of the SPN. "
  type = string
}
variable "spn_permision_contributor" {
  description = "A switch to controle the permission of SPN on the subscription. If true, grant contributor to SPN; if false, grant minimum permision to SPN."
  default     = false
}

##################
variable "kv_name" {
  description = "The name of the Key Vault."
  type = string
  default = ""
}
variable "kv_rbac" {
  description = "A switch to set whether the Key vault uses RBAC or Access Policy to control the authorization of data actions. Default to access policy."
  default     = true
  type        = bool
}

variable "public_key" {
  description = "Path for the ssh public key to be added to the jump servers."
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}
variable "private_key" {
  description = "Path for the ssh private key. This is being used to bootstrap servers."
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "custom_dns" {
  description = "A switch to control the DNS setting one the VNETs. When true, the DNS setting points to custom DNS server. When true, using the Linux jump server in hub VNET as the DNS server; when false, using Azure Default DNS server."
  type    = bool
  default = true
}

variable "owner" {
  type = string
  description = "A string representing the owner. Will be used as prefix of many parameters."
}

variable "public_env" {
  type    = bool
  default = false
  description = "A switch to control the default route on the route tables. When set to false, the default route is pointed to firewall. Default to false."
}

variable "subscription_id" {
  description = "Azure Subscription ID. Mandatory option after AzreuRM 4.0."
  type    = string
}
variable "dns_zone_subscription_id" {
  description = "The subscription id for the private DNS zone subscription."
  default     = null
}

variable "storage_account_tier" {
  default = "Standard"
  type = string
  description = "CDP Storage Account Tier. Default to `Standard`. "
}
variable "storage_account_replication_type" {
  default = "LRS"
  type = string
  description = "CDP Storage Account replication type."
}

variable "tenant_id" {
  type = string
  description = "tenant ID of the Azure AD. "
}

variable "enable_dw" {
  type = bool
  default = true
  description = "Enable DW permissions. Default to true."
}

variable "enable_liftie" {
  type = bool
  default = true
  description = "Enable Liftie permissions. Default to true."
}

variable "enable_de" {
  type = bool
  default = true
  description = "Enable Liftie permissions. Default to true."
}

variable "ds_custom_role" {
  type = string
  default = null
  description = "This is the custom role for data services to be granted to managed identity. If not provide, the template will create a default name."
}