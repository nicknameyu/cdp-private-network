
resource "aws_key_pair" "ssh_pub" {
  key_name   = "${var.owner}-ssh-key"
  public_key = file(var.ssh_key.public_key_path)
}

############### Storage Location Base #################
resource "aws_s3_bucket" "cdp" {
  bucket = var.cdp_bucket_name == null ? "${var.owner}-cdp-poc-bucket" : var.cdp_bucket_name

  tags = {
    Name        = "${var.owner}-cdp-bucket"
    owner       = var.owner
  }
}

resource "aws_s3_object" "folders" {
  for_each = toset(["data", "logs", "backups", "ranger"])
  bucket = aws_s3_bucket.cdp.id
  key    = "${each.value}/"
  source = "/dev/null"
}

output "storage_locations" {
  value = [for x in aws_s3_object.folders : "${aws_s3_bucket.cdp.id}/${x.key}" ]
}

############### KMS Key ##############
resource "aws_kms_key" "cdp" {
  description             = "KMS key for CDP"
  policy = replace(
    replace(file("./policies/aws-cdp-kms-key-policy.json"), "$${AWS_ACCOUNT_ID}", data.aws_caller_identity.current.account_id),
    "$${CDP_KMS_KEY_ARN}", aws_iam_role.cross_account[0].arn)
  tags = {
    owner = var.owner
  }
}
resource "aws_kms_alias" "cdp" {
  name          = "alias/${var.owner}-cdp-key"
  target_key_id = aws_kms_key.cdp.key_id
}
output "kms_key" {
  value = {
    key_arn = aws_kms_key.cdp.arn
    key_alias_arn = aws_kms_alias.cdp.arn
  }
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

  tags = {
    Name = "${var.owner}-kms-ep-sg"
  }
}
resource "aws_vpc_endpoint" "kms" {
  vpc_id            = aws_vpc.cdp.id
  service_name      = "com.amazonaws.us-west-2.kms"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.cdp["subnet1"].id]

  security_group_ids = [
    aws_security_group.kms.id,
  ]
  private_dns_enabled = true
  tags = {
    Name = "${var.owner}-kms-ep"
  }
}