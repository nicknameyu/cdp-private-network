### default and knox security groups in private VPC ###
locals{
  default_security_group_rules = {
    ssh = {
      cidr_ipv4   = [var.core_vpc.cidr, var.cdp_vpc.cidr]
      from_port   = 22
      to_port     = 22
      ip_protocol = "tcp"
    }
    https = {
      cidr_ipv4   = [var.core_vpc.cidr, var.cdp_vpc.cidr]
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
    }
    mgmt = {
      cidr_ipv4   = [var.cdp_vpc.cidr]
      from_port   = 9443
      to_port     = 9443
      ip_protocol = "tcp"
    }
    internal_tcp = {
      cidr_ipv4   = [var.core_vpc.cidr, var.cdp_vpc.cidr]
      from_port   = 0
      to_port     = 65535
      ip_protocol = "tcp"
    }
    internal_udp = {
      cidr_ipv4   = [var.core_vpc.cidr, var.cdp_vpc.cidr]
      from_port   = 0
      to_port     = 65535
      ip_protocol = "udp"
    }
    icmp = {
      cidr_ipv4   = [var.core_vpc.cidr, var.cdp_vpc.cidr]
      from_port   = -1
      to_port     = -1
      ip_protocol = "icmp"
    }
  }

  knox_security_group_rules = local.default_security_group_rules
}

module "private_vpc_sgs" {
  source = "./security-groups"
  vpc_id = aws_vpc.cdp.id
  knox_ingress_rules = local.knox_security_group_rules
  default_ingress_rules = local.default_security_group_rules
  knox_sg_name = "${var.owner}-cdp-knox-sg"
  default_sg_name = "${var.owner}-cdp-default-sg"
  tags = var.tags
}

### default and knox security groups on public VPC###
locals {
  pub_vpc_knox_sg_rules = {
    TCP = {
      cidr_ipv4   = ["0.0.0.0/0"]
      from_port   = 0
      to_port     = 65535
      ip_protocol = "tcp"
    }
    UDP = {
      cidr_ipv4   = ["0.0.0.0/0"]
      from_port   = 0
      to_port     = 65535
      ip_protocol = "udp"
    }
  }
  pub_vpc_default_sg_rules = local.pub_vpc_knox_sg_rules
}
module "pub_vpc_sgs" {
  source                = "./security-groups"
  vpc_id                = aws_vpc.core.id
  knox_ingress_rules    = local.pub_vpc_knox_sg_rules
  default_ingress_rules = local.pub_vpc_default_sg_rules
  knox_sg_name          = "${var.owner}-pub-knox-sg"
  default_sg_name       = "${var.owner}-pub-default-sg"
  tags                  = var.tags
}
