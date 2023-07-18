######### universal variables #########
variable "resource_groups" {
  type = object({
    network_rg      = string
    prerequisite_rg = string
    cdp_rg          = string
    vms_rg          = string
  })
}
variable "tags" {}

variable "location" {
  type = string
  default = "westus"
}

############# Networks #############
variable "hub_cidr" {
  default = ["10.128.0.0/16"]
}
variable "cdp_cidr" {
  default = ["10.100.0.0/16"]
}
variable "hub_vnet_name" {
  type = string
}
variable "cdp_vnet_name" {
  type = string
}

variable "hub_subnets" {
  default = {
    AzureFirewallSubnet = ["10.128.0.0/26"]
    coresubnet          = ["10.128.1.0/24"]
    resolversubnet      = ["10.128.0.64/26"]
  }
}
variable "cdp_subnets" {
  default = {
    subnet_26_1 = "10.100.0.0/26", 
    subnet_26_2 = "10.100.0.64/26",
    subnet_25_1 = "10.100.0.128/25",
    subnet_24_1 = "10.100.1.0/24",
    subnet_23_1 = "10.100.2.0/23",
    subnet_22_1 = "10.100.4.0/22",
    subnet_21_1 = "10.100.8.0/21"
  }
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
        "*.hcp.westus.azmk8s.io",                     // AKS
        "mcr.microsoft.com",                          // AKS
        "*.data.mcr.microsoft.com",                   // AKS
        "login.microsoftonline.com",                  // AKS
        "packages.microsoft.com",                     // AKS
        "acs-mirror.azureedge.net",                   // AKS
      ]
      type = "Https"
      port = "443"
    },
  }
}
variable "fw_net_rules" {
  default = {
    ssh_rules = {
      ip_prefix = [
        "44.234.52.96/27"
      ]
      destination_ports = ["6000-6049",]
      protocols         = ["TCP",]
    },
    https_rules = {
      ip_prefix = [ 
        "35.80.24.128/27",
        "35.166.86.177/32",
        "52.36.110.208/32",
        "52.40.165.49/32",
        "3.65.246.128/27",   // EU based Control Plane
        "3.26.127.64/27",    // AP based control plane
      ]
      destination_ports = ["443",]
      protocols         = ["TCP",]
    }
  }
}


variable "firewall_name" {
  type = string
}

########### prerequisites #############
variable "managed_id" {}
variable "cdp_storage" {
  type = string
}
variable "custom_role_names" {
}

########### Servers ############
variable "dns_server_name" {
  type = string
}
variable "hub_jump_server_name" {
  type = string
}
variable "cdp_jump_server_name" {
  type = string
}
variable "admin_username" {
  type = string
}
