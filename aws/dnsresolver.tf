################# DNS config for CDP VPC ###############
resource "aws_vpc_dhcp_options" "cdp" {
  domain_name          = "${var.region}.compute.internal"
  domain_name_servers  = var.custom_dns ? [aws_instance.core-jump.private_ip] : ["AmazonProvidedDNS"]

  tags = merge({
    Name = "${var.owner}-cdp-dopt"
  }, var.tags)
}
resource "aws_vpc_dhcp_options_association" "cdp" {
  vpc_id          = aws_vpc.cdp.id
  dhcp_options_id = aws_vpc_dhcp_options.cdp.id
}

################# DNS config for CORE VPC ###############
resource "aws_vpc_dhcp_options" "core" {
  domain_name          = "${var.region}.compute.internal"
  domain_name_servers  = var.custom_dns ? [aws_instance.core-jump.private_ip] : ["AmazonProvidedDNS"]

  tags = merge({
    Name = "${var.owner}-core-dopt"
  }, var.tags)
}
resource "aws_vpc_dhcp_options_association" "core" {
  vpc_id          = aws_vpc.core.id
  dhcp_options_id = aws_vpc_dhcp_options.core.id
}

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