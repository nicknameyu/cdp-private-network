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
resource "aws_route" "core-public-cdp" {
  for_each                  = local.core_public_subnets
  route_table_id            = aws_route_table.core_public[each.key].id
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

# Route from public subnets in core VPC to firewall
resource "aws_route" "core-public-fw" {
  for_each                  = local.core_public_subnets
  route_table_id            = aws_route_table.core_public[each.key].id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id                = var.public_snet_to_firewall ? null : aws_internet_gateway.igw.id
  vpc_endpoint_id           = var.public_snet_to_firewall ? (tolist(aws_networkfirewall_firewall.fw.firewall_status[0].sync_states))[0].attachment[0].endpoint_id : null
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
