##################### VPCs ######################
resource "aws_vpc" "core" {
  cidr_block = var.core_vpc.cidr
  enable_dns_support = true
  tags = merge({ Name = var.core_vpc.name }, var.tags)
}
resource "aws_vpc" "cdp" {
  cidr_block = var.cdp_vpc.cidr
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = var.cdp_vpc.name
    owner = var.owner
  }
}

resource "aws_subnet" "core" {
  for_each = local.core_subnets
  vpc_id     = aws_vpc.core.id
  cidr_block = each.value.cidr
  availability_zone = data.aws_availability_zones.available.names[each.value.az_sn]

  tags = merge({
    Name = each.value.name
  }, var.tags)
}
resource "aws_subnet" "cdp" {
  for_each = local.cdp_subnets
  vpc_id = aws_vpc.cdp.id
  cidr_block = each.value.cidr
  availability_zone = data.aws_availability_zones.available.names[each.value.az_sn]

  tags = merge({
    Name = each.value.name
    "kubernetes.io/role/internal-elb" = 1
  }, var.tags)

  lifecycle {
    ignore_changes = [ tags, tags_all ]
  }
}

resource "aws_route_table" "core" {
  for_each = local.core_subnets
  vpc_id = aws_vpc.core.id

  tags = merge({
    Name = "rt_${each.value.name}"
  }, var.tags)

}

resource "aws_route_table_association" "core" {
  for_each       = local.core_subnets
  subnet_id      = aws_subnet.core[each.key].id
  route_table_id = aws_route_table.core[each.key].id
}

resource "aws_route_table" "cdp" {
  for_each = local.cdp_subnets
  vpc_id = aws_vpc.cdp.id

  tags = merge({
    Name = "rt_${each.value.name}"
  }, var.tags)
}

resource "aws_route_table_association" "cdp" {
  for_each       = local.cdp_subnets
  subnet_id      = aws_subnet.cdp[each.key].id
  route_table_id = aws_route_table.cdp[each.key].id
}

##################### IGW ######################
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.core.id

  tags = merge({
    Name = var.igw_name
  }, var.tags)
}

resource "aws_route_table" "igw" {
  vpc_id = aws_vpc.core.id

  dynamic route{
    for_each = setsubtract(setsubtract(["core", "private", "nat"], var.firewall_control ? []:["nat"]), var.public_snet_to_firewall ? []:["core"])
    # for_each = var.firewall_control ? ["core", "private", "nat"]:["core", "private"]
    content {
      cidr_block = local.core_subnets[route.value].cidr
      vpc_endpoint_id = (tolist(aws_networkfirewall_firewall.fw.firewall_status[0].sync_states))[0].attachment[0].endpoint_id
    }
  }
  tags = merge({
    Name = "rt_igw"
  }, var.tags)
}

resource "aws_route_table_association" "igw" {
  gateway_id     = aws_internet_gateway.igw.id
  route_table_id = aws_route_table.igw.id
}

##################### NAT GW ######################
resource "aws_eip" "nat" {
  domain   = "vpc"
  tags = merge({
    Name = "eip-nat-gw"
  }, var.tags)
}
resource "aws_nat_gateway" "nat" {
  allocation_id     = aws_eip.nat.id
  subnet_id         = aws_subnet.core["nat"].id
  tags = merge({
    Name = var.natgw_name
    owner = var.owner
  }, var.tags)
}

##################### TGW ######################
resource "aws_ec2_transit_gateway" "tgw" {
  dns_support = "disable"
  tags = merge({
    Name = var.tgw_name
  }, var.tags)
}

resource "aws_ec2_transit_gateway_vpc_attachment" "core" {
  subnet_ids         = [aws_subnet.core["private"].id]
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = aws_vpc.core.id
  dns_support        = "disable"
  tags = merge({
    Name = "tgwa-core-vpc"
  }, var.tags)
}
resource "aws_ec2_transit_gateway_vpc_attachment" "cdp" {
  subnet_ids         = [ for snet in aws_subnet.cdp: snet.id ]
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = aws_vpc.cdp.id
  dns_support        = "disable"
  tags = merge({
    Name = "tgwa-cdp-vpc"
  }, var.tags)
}
##################### Route ######################
# Route between CDP VPC to Core VPC
resource "aws_route" "cdp-core" {
  for_each                  = local.cdp_subnets
  route_table_id            = aws_route_table.cdp[each.key].id
  destination_cidr_block    = var.core_vpc.cidr
  transit_gateway_id        = aws_ec2_transit_gateway.tgw.id
}
resource "aws_route" "core-cdp" {
  for_each                  = local.core_subnets
  route_table_id            = aws_route_table.core[each.key].id
  destination_cidr_block    = var.cdp_vpc.cidr
  transit_gateway_id        = aws_ec2_transit_gateway.tgw.id
}

# Route from CDP VPC to internet
resource "aws_route" "cdp-nat" {
  for_each                  = local.cdp_subnets
  route_table_id            = aws_route_table.cdp[each.key].id
  destination_cidr_block    = "0.0.0.0/0"
  transit_gateway_id        = aws_ec2_transit_gateway.tgw.id
}
resource "aws_ec2_transit_gateway_route" "tgw-nat" {
  transit_gateway_route_table_id   = aws_ec2_transit_gateway.tgw.association_default_route_table_id
  destination_cidr_block           = "0.0.0.0/0"
  transit_gateway_attachment_id    = aws_ec2_transit_gateway_vpc_attachment.core.id
}

# Route from NAT GW subnet and core subnet to Firewall
resource "aws_route" "core-fw" {
  for_each                  = setsubtract(keys(local.core_subnets), ["firewall", "private", "nat"])
  route_table_id            = aws_route_table.core[each.key].id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id                = var.public_snet_to_firewall ? null : aws_internet_gateway.igw.id
  vpc_endpoint_id           = var.public_snet_to_firewall ? (tolist(aws_networkfirewall_firewall.fw.firewall_status[0].sync_states))[0].attachment[0].endpoint_id : null
}
resource "aws_route" "nat-egress" {
  route_table_id            = aws_route_table.core["nat"].id
  destination_cidr_block    = "0.0.0.0/0"
  # If firewall_control is yes, route to firewall, or route to IGW.
  vpc_endpoint_id           = var.firewall_control ? (tolist(aws_networkfirewall_firewall.fw.firewall_status[0].sync_states))[0].attachment[0].endpoint_id : null
  gateway_id                = var.firewall_control ? null : aws_internet_gateway.igw.id
}
# Route from private subnet to NAT gateway
resource "aws_route" "private-nat" {
  route_table_id            = aws_route_table.core["private"].id
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id            = aws_nat_gateway.nat.id
}

# Route from firewall to IGW
resource "aws_route" "fw-igw" {
  route_table_id            = aws_route_table.core["firewall"].id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id                = aws_internet_gateway.igw.id
}

# Route to S3 VPC endpoint
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.cdp.id
  service_name = "com.amazonaws.${var.region}.s3"

  tags = merge({
    Name = "${var.owner}-s3-endpoint"
  }, var.tags)
}

resource "aws_vpc_endpoint_route_table_association" "cdp-s3" {
   for_each                   = local.cdp_subnets
   route_table_id             = aws_route_table.cdp[each.key].id
   vpc_endpoint_id            = aws_vpc_endpoint.s3.id
}

############### KMS private endpoint ##############
resource "aws_security_group" "kms" {
  name        = "${var.owner}-kms-ep-sg"
  description = "Security group for KMS VPC endpoint"
  vpc_id      = aws_vpc.cdp.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "TCP"
    cidr_blocks      = [aws_vpc.cdp.cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge({
    Name = "${var.owner}-kms-ep-sg"
  }, var.tags)
}
resource "aws_vpc_endpoint" "kms" {
  vpc_id            = aws_vpc.cdp.id
  service_name      = "com.amazonaws.${var.region}.kms"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.cdp["subnet1"].id]

  security_group_ids = [
    aws_security_group.kms.id,
  ]
  private_dns_enabled = true
  tags = merge({
    Name = "${var.owner}-kms-ep"
  }, var.tags)
}

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

  protocols = ["Do53", "DoH"]

  tags = var.tags
}

output "cdp_dns_resolver_endpoint" {
  value = aws_route53_resolver_endpoint.cdp.ip_address[*].ip
}