##################### VPCs ######################
resource "aws_vpc" "core" {
  cidr_block = var.core_vpc.cidr
  enable_dns_support = var.aws_dns
  tags = {
    Name = var.core_vpc.name
    owner = var.owner
  }
}
resource "aws_vpc" "cdp" {
  cidr_block = var.cdp_vpc.cidr
  enable_dns_support = var.aws_dns
  enable_dns_hostnames = true
  tags = {
    Name = var.cdp_vpc.name
    owner = var.owner
  }
}

resource "aws_subnet" "core" {
  for_each = var.core_subnets
  vpc_id     = aws_vpc.core.id
  cidr_block = each.value.cidr
  availability_zone = data.aws_availability_zones.available.names[each.value.az_sn]

  tags = {
    Name = each.value.name
    owner = var.owner
  }
}
resource "aws_subnet" "cdp" {
  for_each = var.cdp_subnets
  vpc_id = aws_vpc.cdp.id
  cidr_block = each.value.cidr
  availability_zone = data.aws_availability_zones.available.names[each.value.az_sn]

  tags = {
    Name = each.value.name
    owner = var.owner
  }
  lifecycle {
    ignore_changes = [ tags, tags_all ]
  }
}

resource "aws_route_table" "core" {
  for_each = var.core_subnets
  vpc_id = aws_vpc.core.id

  tags = {
    Name = "rt_${each.value.name}"
    owner = var.owner
  }
}

resource "aws_route_table_association" "core" {
  for_each       = var.core_subnets
  subnet_id      = aws_subnet.core[each.key].id
  route_table_id = aws_route_table.core[each.key].id
}

resource "aws_route_table" "cdp" {
  for_each = var.cdp_subnets
  vpc_id = aws_vpc.cdp.id

  tags = {
    Name = "rt_${each.value.name}"
    owner = var.owner
  }
}

resource "aws_route_table_association" "cdp" {
  for_each       = var.cdp_subnets
  subnet_id      = aws_subnet.cdp[each.key].id
  route_table_id = aws_route_table.cdp[each.key].id
}

##################### IGW ######################
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.core.id

  tags = {
    Name = var.igw_name
    owner = var.owner
  }
}

resource "aws_route_table" "igw" {
  vpc_id = aws_vpc.core.id

  dynamic route{
    for_each = var.firewall_control ? ["core", "private", "nat"]:["core", "private"]
    content {
      cidr_block = var.core_subnets[route.value].cidr
      vpc_endpoint_id = (tolist(aws_networkfirewall_firewall.fw.firewall_status[0].sync_states))[0].attachment[0].endpoint_id
    }
  }
  tags = {
    Name = "rt_igw"
    owner = var.owner
  }
}

resource "aws_route_table_association" "igw" {
  gateway_id     = aws_internet_gateway.igw.id
  route_table_id = aws_route_table.igw.id
}

##################### NAT GW ######################
resource "aws_eip" "nat" {
  domain   = "vpc"
  tags = {
    Name = "eip-nat-gw"
    owner = var.owner
  }
}
resource "aws_nat_gateway" "nat" {
  allocation_id     = aws_eip.nat.id
  subnet_id         = aws_subnet.core["nat"].id
  tags = {
    Name = var.natgw_name
    owner = var.owner
  }
}

##################### TGW ######################
resource "aws_ec2_transit_gateway" "tgw" {
  dns_support = "disable"
  tags = {
    Name = var.tgw_name
    owner = var.owner
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "core" {
  subnet_ids         = [aws_subnet.core["private"].id]
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = aws_vpc.core.id
  dns_support        = "disable"
  tags = {
    Name = "tgwa-core-vpc"
    owner = var.owner
  }
}
resource "aws_ec2_transit_gateway_vpc_attachment" "cdp" {
  subnet_ids         = [ for snet in aws_subnet.cdp: snet.id ]
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = aws_vpc.cdp.id
  dns_support        = "disable"
  tags = {
    Name = "tgwa-cdp-vpc"
    owner = var.owner
  }
}
##################### Route ######################
# Route between CDP VPC to Core VPC
resource "aws_route" "cdp-core" {
  for_each                  = var.cdp_subnets
  route_table_id            = aws_route_table.cdp[each.key].id
  destination_cidr_block    = var.core_vpc.cidr
  transit_gateway_id        = aws_ec2_transit_gateway.tgw.id
}
resource "aws_route" "core-cdp" {
  for_each                  = var.core_subnets
  route_table_id            = aws_route_table.core[each.key].id
  destination_cidr_block    = var.cdp_vpc.cidr
  transit_gateway_id        = aws_ec2_transit_gateway.tgw.id
}

# Route from CDP VPC to internet
resource "aws_route" "cdp-nat" {
  for_each                  = var.cdp_subnets
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
  for_each                  = setsubtract(keys(var.core_subnets), ["firewall", "private", "nat"])
  route_table_id            = aws_route_table.core[each.key].id
  destination_cidr_block    = "0.0.0.0/0"
  vpc_endpoint_id           = (tolist(aws_networkfirewall_firewall.fw.firewall_status[0].sync_states))[0].attachment[0].endpoint_id
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

  tags = {
    Name = "${var.owner}-s3-endpoint"
    owner = var.owner
  }
}

resource "aws_vpc_endpoint_route_table_association" "cdp-s3" {
   for_each                   = var.cdp_subnets
   route_table_id             = aws_route_table.cdp[each.key].id
   vpc_endpoint_id            = aws_vpc_endpoint.s3.id
}
# Route to Dynamo DB VPC endpoint
# https://docs.cloudera.com/data-warehouse/cloud/aws-environments/topics/dw-aws-private-networking-prerequisites.html#pnavId1
# This is weird that CDP is not creating DynamoDB, why need VPC endpoint for DynamoDB?
# resource "aws_vpc_endpoint" "dynamodb" {
#   vpc_id       = aws_vpc.cdp.id
#   service_name = "com.amazonaws.${var.region}.dynamodb"

#   tags = {
#     Name = "${var.owner}-dynamodb-endpoint"
#     owner = var.owner
#   }
# }

# resource "aws_vpc_endpoint_route_table_association" "cdp-dynamodb" {
#    for_each                   = var.cdp_subnets
#    route_table_id             = aws_route_table.cdp[each.key].id
#    vpc_endpoint_id            = aws_vpc_endpoint.dynamodb.id
# }
