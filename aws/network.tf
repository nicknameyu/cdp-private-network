##################### VPCs ######################
resource "aws_vpc" "core" {
  cidr_block = var.core_vpc.cidr
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = merge({ Name = var.core_vpc.name == "" ? "${var.owner}_core_vpc" : var.core_vpc.name }, var.tags)
}
resource "aws_vpc" "cdp" {
  cidr_block = var.cdp_vpc.cidr
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = merge({ Name = var.cdp_vpc.name == "" ? "${var.owner}_cdp_vpc" : var.cdp_vpc.name }, var.tags)
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
resource "aws_subnet" "core_public" {
  for_each          = local.core_public_subnets
  vpc_id            = aws_vpc.core.id
  cidr_block        = each.value.cidr
  availability_zone = data.aws_availability_zones.available.names[each.value.az_sn]
  map_public_ip_on_launch = true

  tags = merge({
    Name = each.value.name,
    "kubernetes.io/role/elb" = 1
  }, var.tags)
  lifecycle {
    ignore_changes = [ tags, tags_all ]
  }
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
resource "aws_route_table" "core_public" {
  for_each = local.core_public_subnets
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
resource "aws_route_table_association" "core_public" {
  for_each       = local.core_public_subnets
  subnet_id      = aws_subnet.core_public[each.key].id
  route_table_id = aws_route_table.core_public[each.key].id
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
    Name = var.igw_name == "" ? "${var.owner}_igw" : var.igw_name
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
    Name = var.natgw_name == "" ? "${var.owner}_natgw" : var.natgw_name
    owner = var.owner
  }, var.tags)
}

##################### TGW ######################
resource "aws_ec2_transit_gateway" "tgw" {
  dns_support = "disable"
  tags = merge({
    Name = var.tgw_name == "" ? "${var.owner}_tgw" : var.tgw_name
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