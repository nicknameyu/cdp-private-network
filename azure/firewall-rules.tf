variable "fw_app_rules" {
  default = {
    https_rules = {
      target_fqdns = [ 
        "raw.githubusercontent.com", 
        "github.com",
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
        "management.azure.com",                       // Azure	
        "*.agentsvc.azure-automation.net",            // MS LogAnalytics Optional
        "*.ods.opinsights.azure.com",                 // MS LogAnalytics Optional
        "*.oms.opinsights.azure.com",                 // MS LogAnalytics Optional
        "www.digicert.com",                           // Digicert
        "cacerts.digicert.com",                       // Digicert
        "*.cacerts.digicert.com",                       // Digicert
        "mcr.microsoft.com",                          // AKS
        "*.data.mcr.microsoft.com",                   // AKS
        "login.microsoftonline.com",                  // AKS
        "packages.microsoft.com",                     // AKS
        "acs-mirror.azureedge.net",                   // AKS
        "packages.aks.azure.com",                     // AKS, requested by MS on notice to replace the acs-mirror.azureedge.net which will be deprecated by 9/30/2027
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
        "www.microsoft.com",                          // Testing result, this is required by CDE.   8/14/2025
//        "truststore.pki.rds.amazonaws.com",

        "*.snapcraft.io"                              // snap for ubuntu
      ]
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
      type = "Http"
      port = "80"
    }
  }
}
variable "fw_net_rules" {
  default = {
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
