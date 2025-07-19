# Route to S3 VPC endpoint
resource "aws_vpc_endpoint" "s3_cdp" {
  vpc_id       = aws_vpc.cdp.id
  service_name = "com.amazonaws.${var.region}.s3"

  tags = merge({
    Name = "${var.owner}-s3-endpoint-cdp"
  }, var.tags)
}

resource "aws_vpc_endpoint_route_table_association" "cdp-s3" {
   for_each                   = local.cdp_subnets
   route_table_id             = aws_route_table.cdp[each.key].id
   vpc_endpoint_id            = aws_vpc_endpoint.s3_cdp.id
}

resource "aws_vpc_endpoint" "s3_core" {
  vpc_id       = aws_vpc.core.id
  service_name = "com.amazonaws.${var.region}.s3"

  tags = merge({
    Name = "${var.owner}-s3-endpoint-core"
  }, var.tags)
}


resource "aws_vpc_endpoint_route_table_association" "core-public-s3" {
   for_each          = local.core_public_subnets
   route_table_id             = aws_route_table.core_public[each.key].id
   vpc_endpoint_id            = aws_vpc_endpoint.s3_core.id
}

resource "aws_vpc_endpoint_route_table_association" "core-s3" {
   route_table_id             = aws_route_table.core["core"].id
   vpc_endpoint_id            = aws_vpc_endpoint.s3_core.id
}
