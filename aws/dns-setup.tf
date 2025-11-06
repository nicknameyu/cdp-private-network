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
  domain_name_servers  = ["AmazonProvidedDNS"]

  tags = merge({
    Name = "${var.owner}-core-dopt"
  }, var.tags)
}
resource "aws_vpc_dhcp_options_association" "core" {
  vpc_id          = aws_vpc.core.id
  dhcp_options_id = aws_vpc_dhcp_options.core.id
}
