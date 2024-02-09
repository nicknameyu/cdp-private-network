variable "owner" {
  description = "Owner name. Will be used as prefix of many resources created by this template."
  type = string
}
variable "region" {
  type = string
  default = "us-west-2"
}
variable "cdp_bucket_name" {
  type = string
  default = null
}
variable "core_vpc" {
  type = object({
    name = string
    cidr = string
  })
}

variable "cdp_vpc"{
  type = object({
    name = string
    cidr = string
  })
}
variable "tgw_name" {
  description = "Name of the trasit gateway."
  type = string
}
variable "fw_name" {
  description = "Name of the firewall."
  type = string
}
variable "core_subnets" {
  type = map(object({
    name = string
    cidr = string
    az_sn = number 
  }))
  default = {
    core = {
        name = "coresubnet"
        cidr = "10.1.0.0/28"
        az_sn   = 0
    }
    nat = {
        name = "natsubnet"
        cidr = "10.1.0.16/28"
        az_sn   = 0
    }
    firewall = {
        name = "firewallsubnet"
        cidr = "10.1.0.32/28"
        az_sn   = 0
    }
    private = {
        name = "privatesubnet"
        cidr = "10.1.0.48/28"
        az_sn   = 0
    }
  }
}

variable "cdp_subnets" {
  type = map(object({
    name = string
    cidr = string
    az_sn = number // az_sn is the serial number of availability zone, indicates the numer "az_sn" AZ to deploy this subnet into.
  }))
  default = {
    subnet1 = {
        name    = "subnet1"
        cidr    = "10.2.0.0/24"
        az_sn   = 0
    }
    subnet2 = {
        name    = "subnet2"
        cidr    = "10.2.1.0/24"
        az_sn   = 1
    }
    subnet3 = {
        name    = "subnet3"
        cidr    = "10.2.3.0/24"
        az_sn   = 2
    }
  }
}

variable "ssh_key" {
  description = "The public key will be used to create an SSH public key in the instances. The RSA private key is used to decrypt the password created for the DNS server."
  type = object({
    public_key_path      = string
    private_rsa_key_path = string
  })
  default = {
    public_key_path      = "~/.ssh/id_rsa.pub"
    private_rsa_key_path = "~/.ssh/id_rsa.rsa"
  }
}

variable "igw_name" {
  description = "Name of the internet gateway."
  type = string
}
variable "natgw_name" {
  description = "Name of the NAT gateway."
  type = string
}

variable "create_cross_account_role" {
  type = bool
  description = "A switch to control whether to create cross account role. Default to true. "
  default = true
}

variable "fw_domain_ep" {
  # https://docs.cloudera.com/cdp-public-cloud/cloud/requirements-aws/topics/mc-outbound_access_requirements.html
  default = [
    # Cloudera CCMv2
    ## US Based Control Plane
    ".v2.us-west-1.ccm.cdp.cloudera.com",
    ## EU Based Control plane
    ".v2.ccm.eu-1.cdp.cloudera.com",
    ## AP Based control plane
    ".v2.ccm.ap-1.cdp.cloudera.com",

    # Cloudera Databus
    ## US Based Control Plane
    "dbusapi.us-west-1.sigma.altus.cloudera.com",
    "cloudera-dbus-prod.s3.amazonaws.com",
    ## EU Based Control Plane
    "api.eu-1.cdp.cloudera.com",
    "mow-prod-eu-central-1-sigmadbus-dbus.s3.eu-central-1.amazonaws.com",
    "mow-prod-eu-central-1-sigmadbus-dbus.s3.amazonaws.com",
    ## AP Based Control Plane
    "api.ap-1.cdp.cloudera.com",
    "mow-prod-ap-southeast-2-sigmadbus-dbus.s3.ap-southeast-2.amazonaws.com",
    "mow-prod-ap-southeast-2-sigmadbus-dbus.s3.amazonaws.com",

    # Cloudera Manager parcels
    "archive.cloudera.com",

    # Control Plane API
    ## US Based Control Plane
    "api.us-west-1.cdp.cloudera.com",
    ## EU Based Control Plane
    "api.eu-1.cdp.cloudera.com",
    ## AP Based Control Plane
    "api.ap-1.cdp.cloudera.com",

    # RPMs
    "cloudera-service-delivery-cache.s3.amazonaws.com",
    # Docker Images
    "container.repository.cloudera.com",
    "docker.repository.cloudera.com",
    "container.repo.cloudera.com",
    ## US Based control plane
    "prod-us-west-2-starport-layer-bucket.s3.us-west-2.amazonaws.com",
    "prod-us-west-2-starport-layer-bucket.s3.amazonaws.com",
    "s3-r-w.us-west-2.amazonaws.com",
    ".execute-api.us-west-2.amazonaws.com",
    ## EU Based control plane
    "prod-eu-west-1-starport-layer-bucket.s3.eu-west-1.amazonaws.com",
    "prod-eu-west-1-starport-layer-bucket.s3.amazonaws.com",
    "s3-r-w.eu-west-1.amazonaws.com",
    ".execute-api.eu-west-1.amazonaws.com",
    
    ## AP Based control plane
    "prod-ap-southeast-1-starport-layer-bucket.s3.ap-southeast-1.amazonaws.com",
    "prod-ap-southeast-1-starport-layer-bucket.s3.amazonaws.com",
    "s3-r-w.ap-southeast-1.amazonaws.com",
    ".execute-api.ap-southeast-1.amazonaws.com",





    # global endpoint
    "raw.githubusercontent.com",
    "github.com",
    ".s3.amazonaws.com",
    "archive.cloudera.com",
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
    "consoleauth.us-west-1.core.altus.cloudera.com",
    "consoleauth.altus.cloudera.com",
    "pypi.org",
    # regional endpoint
    # US
    ".s3.us-west-1.amazonaws.com",
    ".s3.eu-central-1.amazonaws.com",
    ".s3.ap-southeast-2.amazonaws.com",
  
    ".cdp.cloudera.com",
    ".v2.ccm.cdp.cloudera.com",
    ".v2.us-west-1.ccm.cdp.cloudera.com",
    "dbusapi.us-west-1.sigma.altus.cloudera.com",
    "api.us-west-1.cdp.cloudera.com",
    ".s3.us-west-2.amazonaws.com",
    # EU
    "api.eu-1.cdp.cloudera.com",
    ".s3.eu-west-1.amazonaws.com",
    # AP
    "api.ap-1.cdp.cloudera.com",
    ".s3.ap-southeast-1.amazonaws.com",


    # Public Signing Key Retrieval for Data Engineering DataFlow
    "console.us-west-1.cdp.cloudera.com",
    "console.eu-1.cdp.cloudera.com",
    "console.ap-1.cdp.cloudera.com",

    # AWS STS
    "sts.amazonaws.com",
    ".rds.amazonaws.com",  
    # Public domains
    ".google.com",
    "cloudera.okta.com",
    # aws cli
    "awscli.amazonaws.com",
    # k8s
    "dl.k8s.io",
    "cdn.dl.k8s.io",
    "pkgs.k8s.io",
    "prod-cdn.packages.k8s.io",

    # Flow Definition storage for DF
    # "s3.us-west-2.amazonaws.com",
    "dfx-flow-artifacts.mow-prod.mow-prod.cloudera.com",
    "cldr-mow-prod-eu-central-1-dfx-flow-artifacts.s3.eu-central-1.amazonaws.com",
    "cldr-mow-prod-ap-southeast-2-dfx-flow-artifacts.s3.ap-southeast-2.amazonaws.com",

    # Missing endpoints
    "iamapi.us-west-1.altus.cloudera.com",  # DSE-34294
  ]
}

locals {
  fw_regional_domain_ep = [
    # these are AWS regional service endpoint. Can be converted to VPC enpoints. 
    # these are not required when creating environment and datalake and datahub. They are required for EKS based data services.
    "sts.${var.region}.amazonaws.com", 
    # ".s3.${var.region}.amazonaws.com",                # Not required as gateway endpoint is recommended .
    "api.ecr.${var.region}.amazonaws.com",              # Firewall rule is recommended .
    ".dkr.ecr.${var.region}.amazonaws.com",             # Firewall rule is recommended .
    "ec2.${var.region}.amazonaws.com",                  # Firewall rule is recommended
    "eks.${var.region}.amazonaws.com",                  # Firewall rule is recommended
    "cloudformation.${var.region}.amazonaws.com",       # Cloudformation is seldom used, a firewall rule should be okay.
    "autoscaling.${var.region}.amazonaws.com",          # why autoscaling need a private endpoint?
    "elasticfilesystem.${var.region}.amazonaws.com",    # Firewall rule is recommended
    "elasticloadbalancing.${var.region}.amazonaws.com", # Firewall rule is recommended
    # "rds.${var.region}.amazonaws.com",                # not necessary. Testing result
    "servicequotas.${var.region}.amazonaws.com",        # Firewall rule is recommended
    "pricing.${var.region}.amazonaws.com",              # Firewall rule is recommended
  ]
  fw_domain_ep = concat(var.fw_domain_ep, local.fw_regional_domain_ep)
}

variable "fw_http_ep" {
  type = list(string)
  default = [     
    # Ubuntu update
    "security.ubuntu.com",
    ".ec2.archive.ubuntu.com",
    ".archive.canonical.com" ]
}

variable "aws_sso_user_arn_keyword" {
  description = "This keyword is used to create trust relationship between the cross account role and the target user, so that the user can assume this role for operation activities."
  type = string
  default = "cldr_poweruser"
}

variable "firewall_control" {
  type = bool
  default = true
  description = "This is to control whether CDP VPC internet traffic is controled by firewall. For testing purpose."
}
variable "public_snet_to_firewall" {
  type = bool
  default = true
  description = "This is to control whether public subnet internet traffic is controled by firewall. For testing purpose."
}

variable "custom_dns" {
  type = bool
  description = "This is to control whether we use custom DNS in CDP VPC"
  default = false
}