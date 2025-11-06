
################ DNS private resolver for CDP VPC ############

resource "aws_security_group" "cdp_dns_resolver" {
  name   = "${var.owner}-cdp-dns-resolver-sg"
  vpc_id = aws_vpc.cdp.id

  ingress {
    description      = "DNS"
    from_port        = 53
    to_port          = 53
    protocol         = "UDP"
    cidr_blocks      = [var.core_vpc.cidr, var.cdp_vpc.cidr]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  tags   = var.tags
}

resource "aws_route53_resolver_endpoint" "cdp" {
  name      = "${var.owner}-cdp-dns-resolver"
  direction = "INBOUND"

  security_group_ids = [
    aws_security_group.cdp_dns_resolver.id,
  ]

  ip_address {
    subnet_id = aws_subnet.cdp[values(local.cdp_subnets)[0].name].id
  }

  ip_address {
    subnet_id = aws_subnet.cdp[values(local.cdp_subnets)[1].name].id
  }

  ip_address {
    subnet_id = aws_subnet.cdp[values(local.cdp_subnets)[2].name].id
  }
  protocols = ["Do53", "DoH"]

  tags = var.tags
}

output "cdp_dns_resolver_endpoint" {
  value = aws_route53_resolver_endpoint.cdp.ip_address[*].ip
}