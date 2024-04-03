######### universal variables #########
variable "resource_groups" {
  description = "The template will create 4 resource groups to hold resources: the network resource group, the prerequisite resource group, the cdp environment resource group, and the jump server resource group."
  type = object({
    network_rg      = string
    prerequisite_rg = string
    cdp_rg          = string
    vms_rg          = string
  })
}
variable "tags" {
  description = "Tags to be applied to the resources."
  type = map(string)
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
    condition     = tonumber(split("/", var.hub_cidr)[1]) <= 25
    error_message = "A minimum /25 CIDR is required for HUB VNET."
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
  description = "The name of HUB VNET."
  type = string
}
variable "cdp_vnet_name" {
  description = "The name of CDP VNET"
  type = string
}
locals {
  hub_vnet_masknum = tonumber(split("/", var.hub_cidr)[1])
  hub_subnets = {
    AzureFirewallSubnet = [cidrsubnet(var.hub_cidr, 26 - local.hub_vnet_masknum, 0 )]
    coresubnet          = [cidrsubnet(var.hub_cidr, 26 - local.hub_vnet_masknum, 1 )]
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

variable "fw_app_rules" {
  default = {
    https_rules = {
      target_fqdns = [ 
        "raw.githubusercontent.com", 
        "github.com",
        # "*.v2.us-west-1.ccm.cdp.cloudera.com",        // According to doc, this one should be addressed by IP prefix, but actually not. 07/18/2023
        #                                               // nslookup found the ip address for this FQDN is different to those on document.
        #                                               // Doc says: "35.80.24.128/27", "35.166.86.177/32", "52.36.110.208/32", "52.40.165.49/32"
        #                                               // nslookup found: "54.191.65.58", "35.163.159.76", "52.13.59.204"
        "dbusapi.us-west-1.sigma.altus.cloudera.com", // US Based control Plane
        "s3.amazonaws.com",
        "*.s3.amazonaws.com",                         // US Based control plane
        "api.eu-1.cdp.cloudera.com",                  // EU Based control plane
        "api.ap-1.cdp.cloudera.com",                  // AP Based control plane
        "archive.cloudera.com",                       // Parcels
        "api.us-west-1.cdp.cloudera.com",             // US Based control Plane API
        "api.eu-1.cdp.cloudera.com",                  // EU Based control Plane API
        "api.ap-1.cdp.cloudera.com",                  // AP Based control Plane API
        "container.repository.cloudera.com",          // Docker image
        "docker.repository.cloudera.com",             // Docker Image
        "container.repo.cloudera.com",                // Docker Image for data services
        "*.s3.us-west-2.amazonaws.com",               // Docker image for data services
        "s3.us-west-2.amazonaws.com",                 // Document doesn't have this one. But DF will fail to download flows from S3.
        "*.s3.eu-west-1.amazonaws.com",                // Document doesn't have this one. But DW will fail to download flows from S3 in EU.
        "*.s3.eu-1.amazonaws.com",                    // Docker image for data services
        "*.s3.ap-southeast-1.amazonaws.com",          // Docker image for data services
        "s3-r-w.us-west-1.amazonaws.com",                // Docker image for data services
        "*.execute-api.us-west-1.amazonaws.com",         // Docker image for data services
        "auth.docker.io",
        "cloudera-docker-dev.jfrog.io",
        "docker-images-prod.s3.amazonaws.com",
        "gcr.io",
        "k8s.gcr.io",
        "quay-registry.s3.amazonaws.com",
        "quay.io",
        "quayio-production-s3.s3.amazonaws.com",
        "docker.io",
        "*.docker.io",
        "production.cloudflare.docker.com",
        "storage.googleapis.com",
        "consoleauth.altus.cloudera.com",             // Public Signing Key Retrieval US
        "console.us-west-1.cdp.cloudera.com",         // Public Signing Key Retrieval US
        "consoleauth.us-west-1.core.altus.cloudera.com", // This one isn't in document 07/18/2023
        "console.eu-1.cdp.cloudera.com",              // Public Signing Key Retrieval EU
        "console.ap-1.cdp.cloudera.com",              // Public Signing Key Retrieval AP
        "pypi.org",                                   // SQL Stream builder, postgreSQL driver install
        "*.dfs.core.windows.net",                     // Azure storage account
        "*.postgres.database.azure.com",              // PostgresDB
        "management.azure.com",                       // Azure	
        "*.agentsvc.azure-automation.net",            // MS LogAnalytics Optional
        "*.ods.opinsights.azure.com",                 // MS LogAnalytics Optional
        "*.oms.opinsights.azure.com",                 // MS LogAnalytics Optional
        "*.blob.core.windows.net",                    // MS LogAnalytics Optional
        "www.digicert.com",                           // Digicert
        "cacerts.digicert.com",                       // Digicert
        "*.cacerts.digicert.com",                       // Digicert
        "*.hcp.westus.azmk8s.io",                     // AKS
        "mcr.microsoft.com",                          // AKS
        "*.data.mcr.microsoft.com",                   // AKS
        "login.microsoftonline.com",                  // AKS
        "packages.microsoft.com",                     // AKS
        "acs-mirror.azureedge.net",                   // AKS
        "data.policy.core.windows.net",               // AKS Azure Policy
        "store.policy.core.windows.net",              // AKS Azure Policy
        "dc.services.visualstudio.com",               // AKS Azure Policy
        "nvidia.github.io",                           // AKS GPU
        "us.download.nvidia.com",                     // AKS GPU
        "download.docker.com",                        // AKS GPU
        "aka.ms",                                     // Microsoft tools
        "pypi.python.org",                            // Microsoft tools
        "*.github.com",                               // Microsoft tools
        "objects.githubusercontent.com",              // Microsoft tools
        "files.pythonhosted.org",                     // Microsoft tools
        "mirrorlist.centos.org",                      // Centos tools
        "apt.releases.hashicorp.com",                 // hashicorp terraform
      ]
      source_addresses = ["10.0.0.0/8"]
      type = "Https"
      port = "443"
    },
    http_rules = {
      target_fqdns = [
        "security.ubuntu.com",                        // AKS
        "azure.archive.ubuntu.com",                   // AKS
        "changelogs.ubuntu.com",                      // AKS
        "archive.ubuntu.com",                         // AKS
      ]
      source_addresses = ["10.0.0.0/8"]
      type = "Http"
      port = "80"
    }
  }
}
variable "fw_net_rules" {
  default = {
    # ssh_rules = {                                   // testing found this is not required, Aug 31
    #   ip_prefix = [                                 // this is for CCMv1
    #     "44.234.52.96/27"
    #   ]
    #   destination_ports = ["6000-6049",]
    #   protocols         = ["TCP",]
    # },
    https_rules = {
      ip_prefix = [ 
        "35.80.24.128/27",
        "35.166.86.177/32",
        "52.36.110.208/32",
        "52.40.165.49/32",
        "3.65.246.128/27",   // EU based Control Plane
        "3.26.127.64/27",    // AP based control plane
      ]
      source_addresses  = ["10.0.0.0/8"]
      destination_ports = ["443",]
      protocols         = ["TCP",]
    },
    public_subnet = {
      ip_prefix         = ["*"]
      source_addresses  = ["10.128.1.0/24"]
      destination_ports = ["*"]
      protocols         = ["TCP", "UDP"]
    }
  }
}


variable "firewall_name" {
  description = "The name for the Azure Firewall"
  type = string
}

variable "dns_resolver_name" {
  description = "The name for the private DNS resolver on CDP VNET."
  type = string
}
########### prerequisites #############
variable "managed_id" {
  description = "The name of the required managed identities."
  type = object({
    assumer    = string
    dataaccess = string
    logger     = string
    ranger     = string
    raz        = string
    dw         = string
  })
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
    env_single_rg_svc_ep = string
    env_single_rg_pvt_ep = string
//    env_multi_rg_pvt_ep  = string              // this one is deprecated.
    cmk                  = string
    mkt_img              = string                // new added for RHEL8 Azure Market Image
  })
}

########### Servers ############
variable "dns_server_name" {
  description = "The name of the DNS server."
  type        = string
}
variable "hub_jump_server_name" {
  description = "The name of the jump server sitting in hub VNET"
  type        = string
}
variable "cdp_jump_server_name" {
  description = " The name of the jump server sitting in cdp VNET"
  type        = string
}
variable "admin_username" {
  description = "The administrator's name for the DNS server and jump servers."
  type        = string
}
variable "password" {
  description = "The password of the DNS servers"
  type        = string
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
}

variable "public_key" {
  description = "Path for the ssh public key to be added to the jump servers."
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "custom_dns" {
  description = "A switch to control the DNS setting one the VNETs. When true, the DNS setting points to custom DNS server. When true, use Azure Default DNS."
  type    = bool
  default = false
}