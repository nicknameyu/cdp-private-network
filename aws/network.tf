locals {
  // Subnet CIDR calculation
  core_vpc_masknum = tonumber(split("/", var.core_vpc.cidr)[1])
  core_subnets = {
    nat = {
        cidr = cidrsubnet(var.core_vpc.cidr, 28 - local.core_vpc_masknum, 0)
        az_sn   = 0
    }
    firewall = {
        cidr = cidrsubnet(var.core_vpc.cidr, 28 - local.core_vpc_masknum, 1)
        az_sn   = 0
    }
  }
  public_subnets = {
    pub_subnet_1 = {
      cidr    = cidrsubnet(var.core_vpc.cidr, 23 - local.core_vpc_masknum, 1)
      az_sn   = 0
    }
    pub_subnet_2 = {
      cidr    = cidrsubnet(var.core_vpc.cidr, 23 - local.core_vpc_masknum, 2)
      az_sn   = 1
    }
    pub_subnet_3 = {
      cidr    = cidrsubnet(var.core_vpc.cidr, 23 - local.core_vpc_masknum, 3)
      az_sn   = length(data.aws_availability_zones.available.names) > 2 ? 2:0
    }
  }
  hub_private_subnets = {
    pvt_subnet_1 = {
      cidr    = cidrsubnet(var.core_vpc.cidr, 23 - local.core_vpc_masknum, 4)
      az_sn   = 0
    }
    pvt_subnet_2 = {
      cidr    = cidrsubnet(var.core_vpc.cidr, 23 - local.core_vpc_masknum, 5)
      az_sn   = 1
    }
    pvt_subnet_3 = {
      cidr    = cidrsubnet(var.core_vpc.cidr, 23 - local.core_vpc_masknum, 6)
      az_sn   = length(data.aws_availability_zones.available.names) > 2 ? 2:0
    }
  }
  spoke_private_subnets = {
    pvt_subnet_1 = {
      cidr    = cidrsubnet(var.cdp_vpc.cidr, 23 - local.core_vpc_masknum, 4)
      az_sn   = 0
    }
    pvt_subnet_2 = {
      cidr    = cidrsubnet(var.cdp_vpc.cidr, 23 - local.core_vpc_masknum, 5)
      az_sn   = 1
    }
    pvt_subnet_3 = {
      cidr    = cidrsubnet(var.cdp_vpc.cidr, 23 - local.core_vpc_masknum, 6)
      az_sn   = length(data.aws_availability_zones.available.names) > 2 ? 2:0
    }
  }
}
module "hub-spoke" {
  source   = "github.com/nicknameyu/terraform-modules/modules/aws/aws_hubspoke_vpc"
  region   = var.region
  tags     = var.tags

  hub_vpc               =  {
                            name = var.core_vpc.name == "" ? "${var.owner}-hub-vpc" : var.core_vpc.name
                            cidr = var.core_vpc.cidr
                          }
  public_subnets        = local.public_subnets
  hub_private_subnets   = local.hub_private_subnets
  spoke_vpc             = {
                            name = var.cdp_vpc.name == "" ? "${var.owner}-spoke-vpc" : var.cdp_vpc.name
                            cidr = var.cdp_vpc.cidr
                          }
  spoke_private_subnets = local.spoke_private_subnets

  tgw_name              = "${var.owner}-tgw"

  ## Egress
  igw_name              = "${var.owner}-igw"
  nat_name              = "${var.owner}-nat"
  nat_subnet_cidr       = local.core_subnets.nat.cidr
  firewall_name         = "${var.owner}-firewall"
  firewall_subnet_cidr  = local.core_subnets.firewall.cidr

  ## DNS server
  ssh_key_name          = module.env_prerequisites.ssh_key_name
  ssh_private_key       = file(var.ssh_key.private_rsa_key_path)
  custom_dns            = var.custom_dns
}

output "dns_server_private_ip" {
  value = module.hub-spoke.dns_server_private_ip
}
output "dns_server_public_ip" {
  value = module.hub-spoke.dns_server_public_ip
}

## EKS related taggings. This part is not included in the module. 
resource "aws_ec2_tag" "hub_public" {
  for_each = module.hub-spoke.hub_public_subnets
  resource_id = each.value.subnet_id
  key         = "kubernetes.io/role/elb"
  value       = "1"
}
resource "aws_ec2_tag" "hub_private" {
  for_each = module.hub-spoke.hub_private_subnets
  resource_id = each.value.subnet_id
  key         = "kubernetes.io/role/internal-elb"
  value       = "1"
}
resource "aws_ec2_tag" "spoke_public" {
  for_each = module.hub-spoke.spoke_private_subnets
  resource_id = each.value.subnet_id
  key         = "kubernetes.io/role/internal-elb"
  value       = "1"
}