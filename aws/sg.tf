### default and knox security groups ###
resource "aws_security_group" "default" {
  name   = "${var.owner}-cdp-default-sg"
  vpc_id = aws_vpc.cdp.id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  tags   = {
    owner = var.owner
  }
}
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
}
resource "aws_security_group_rule" "default" {
  for_each          = local.default_security_group_rules
  security_group_id = aws_security_group.default.id
  type              = "ingress"
  cidr_blocks       = each.value.cidr_ipv4
  from_port         = each.value.from_port
  protocol          = each.value.ip_protocol
  to_port           = each.value.to_port

}

resource "aws_security_group" "knox" {
  name   = "${var.owner}-cdp-knox-sg"
  vpc_id = aws_vpc.cdp.id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  tags   = {
    owner = var.owner
  }
}
locals{
  knox_security_group_rules = {
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
}
resource "aws_security_group_rule" "knox" {
  for_each          = local.default_security_group_rules
  security_group_id = aws_security_group.knox.id
  type              = "ingress"
  cidr_blocks       = each.value.cidr_ipv4
  from_port         = each.value.from_port
  protocol          = each.value.ip_protocol
  to_port           = each.value.to_port
}
