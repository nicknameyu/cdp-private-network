variable "knox_sg_name" {
  type = string
  default = "cdp_knox_sg"
}
variable "default_sg_name" {
  type = string
  default = "cdp_default_sg"
}
variable "knox_ingress_rules" {
  description = "Security rules map"
  type = map(object({
    cidr_ipv4   = list(string)
    from_port   = number
    to_port     = number
    ip_protocol = string
  }))
}
variable "default_ingress_rules" {
  description = "Security rules map"
  type = map(object({
    cidr_ipv4   = list(string)
    from_port   = number
    to_port     = number
    ip_protocol = string
  }))
}
variable "vpc_id" {
  type = string
}
variable "tags" {
  type = map(string)
  default = null
}

resource "aws_security_group" "default" {
  name   = var.default_sg_name
  vpc_id = var.vpc_id
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  tags   = var.tags
}
resource "aws_security_group_rule" "default" {
  for_each          = var.default_ingress_rules
  security_group_id = aws_security_group.default.id
  type              = "ingress"
  cidr_blocks       = each.value.cidr_ipv4
  from_port         = each.value.from_port
  protocol          = each.value.ip_protocol
  to_port           = each.value.to_port
}
resource "aws_security_group" "knox" {
  name   = var.knox_sg_name
  vpc_id = var.vpc_id
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  tags   = var.tags
}
resource "aws_security_group_rule" "knox" {
  for_each          = var.knox_ingress_rules
  security_group_id = aws_security_group.knox.id
  type              = "ingress"
  cidr_blocks       = each.value.cidr_ipv4
  from_port         = each.value.from_port
  protocol          = each.value.ip_protocol
  to_port           = each.value.to_port
}

output "security_group_ids" {
  value = {
    default_sg_id = aws_security_group.default.id
    knox_sg_id    = aws_security_group.knox.id
  }
}