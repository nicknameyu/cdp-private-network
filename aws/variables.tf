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
  validation {
    condition     = tonumber(split("/", var.core_vpc.cidr)[1]) <= 26
    error_message = "A minimum /26 CIDR is required for core VPC."
  }
  default = {
    cidr = "10.3.0.0/16"
    name = ""
  }
}

variable "cdp_vpc"{
  type = object({
    name = string
    cidr = string
  })
  validation {
    condition     = tonumber(split("/", var.cdp_vpc.cidr)[1]) <= 22
    error_message = "A minimum /22 CIDR is required for cdp VPC."
  }
  default = {
    cidr = "10.4.0.0/16"
    name = ""
  }
}
variable "tgw_name" {
  description = "Name of the trasit gateway."
  type = string
  default = ""
}
variable "fw_name" {
  description = "Name of the firewall."
  type = string
  default = ""
}

locals {
  // Subnet CIDR calculation
  core_vpc_masknum = tonumber(split("/", var.core_vpc.cidr)[1])
  core_subnets = {
    
    core = {
        name = "coresubnet"
        cidr = cidrsubnet(var.core_vpc.cidr, 28 - local.core_vpc_masknum, 0)
        az_sn   = 0
    }
    nat = {
        name = "natsubnet"
        cidr = cidrsubnet(var.core_vpc.cidr, 28 - local.core_vpc_masknum, 1)
        az_sn   = 0
    }
    firewall = {
        name = "firewallsubnet"
        cidr = cidrsubnet(var.core_vpc.cidr, 28 - local.core_vpc_masknum, 2)
        az_sn   = 0
    }
    private = {
        name = "privatesubnet"
        cidr = cidrsubnet(var.core_vpc.cidr, 28 - local.core_vpc_masknum, 3)
        az_sn   = 0
    }
  }
  core_public_subnets = {
    subnet_1 = {
      name    = "pub_subnet_1"
      cidr    = cidrsubnet(var.core_vpc.cidr, 23 - local.core_vpc_masknum, 1)
      az_sn   = 0
    }
    subnet_2 = {
      name    = "pub_subnet_2"
      cidr    = cidrsubnet(var.core_vpc.cidr, 23 - local.core_vpc_masknum, 2)
      az_sn   = 1
    }
    subnet_3 = {
      name    = "pub_subnet_3"
      cidr    = cidrsubnet(var.core_vpc.cidr, 23 - local.core_vpc_masknum, 3)
      az_sn   = length(data.aws_availability_zones.available.names) > 2 ? 2:0
    }
  }
  cdp_vpc_masknum = tonumber(split("/", var.cdp_vpc.cidr)[1])
  cdp_subnets     = {
    subnet1 = {
        name    = "subnet1"
        cidr    = cidrsubnet(var.cdp_vpc.cidr, 23 - local.cdp_vpc_masknum, 0)
        az_sn   = 0
    }
    subnet2 = {
        name    = "subnet2"
        cidr    = cidrsubnet(var.cdp_vpc.cidr, 23 - local.cdp_vpc_masknum, 1)
        az_sn   = 1
    }
    subnet3 = {
        name    = "subnet3"
        cidr    = cidrsubnet(var.cdp_vpc.cidr, 23 - local.cdp_vpc_masknum, 2)
        az_sn   = length(data.aws_availability_zones.available.names) > 2 ? 2:0
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
    private_rsa_key_path = "~/.ssh/id_rsa"
  }
}

variable "igw_name" {
  description = "Name of the internet gateway."
  type = string
  default = ""
}
variable "natgw_name" {
  description = "Name of the NAT gateway."
  type = string
  default = ""
}

variable "cross_account_role" {
  type = string
  description = "A switch to control whether to create cross account role. Cross account role will be created if this is null, or cross account role will be imported. Default to null. "
  default = null
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
    "download.postgresql.org",
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

    # For NIFI Operator
    "get.helm.sh",
    ".docker.com",
    ".github.io",
    ".githubusercontent.com",
    "api.github.com"
  ]
}

locals {
  fw_regional_domain_ep = [
    # https://docs.cloudera.com/cdp-public-cloud/cloud/requirements-aws/topics/mc-outbound_access_requirements.html#pnavId2
    # these are AWS regional service endpoint. Can be converted to VPC enpoints. 
    # these are not required when creating environment and datalake and datahub. They are required for EKS based data services.
    "sts.${var.region}.amazonaws.com", 
    # ".s3.${var.region}.amazonaws.com",                # Not required as gateway endpoint is recommended .
    "api.ecr.${var.region}.amazonaws.com",              # Firewall rule is recommended .
    ".dkr.ecr.${var.region}.amazonaws.com",             # Firewall rule is recommended .
    "ec2.${var.region}.amazonaws.com",                  # Firewall rule is recommended
    "eks.${var.region}.amazonaws.com",                  # Firewall rule is recommended
    # "UNIQUEID.*.eks.amazonaws.com",                   # This is on document for DW, but actually not required.
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
  default = true
}
variable "cmk_key_name" {
  type = string
  default = null
  description = "The alias of KMS key to be created. Default to null. If null, a key with alias \"<owner>-cdp-key\" is created. If not null, the value will be used to create the alias."
}
variable "default_permission" {
  type = bool
  default = true
  description = "A switch to control whether to use default permission or reduced permission. Default to true."
}

variable "create_eks_role" {
  type = bool
  default = false
  description = "This is a switch to control whether to create Cloudformation stack for EKS role/instance profile under reduced permission."
}
variable "cdp_xaccount_account_id" {
  type = string
  default = "387553343826"
  description = "This is the AWS account ID to be trused by the cross account role. Default to NA Sandbox tenant AWS account. Please customize it when using different tenant."
}

variable "cdp_xaccount_external_id" {
  type = string
  default = null
  description = "This is the AWS External ID to be trused by the cross account role. Default to null. Please customize it when using existing cross account role."
}

variable "create_windows_jumpserver" {
  type = bool
  default = false
  description = "This is a switch to control whether to create a windows server as a jump server in public subnet. Default to false."
}

variable "tags" {
  description = "Tags to be applied to the resources."
  type = map(string)
  default = null
}

variable "customer_xa_policy" {
  description = "List of path to policy files provided by customer."
  type = list(string)
  default = null
}