
resource "aws_key_pair" "ssh_pub" {
  key_name   = "${var.owner}-ssh-key"
  public_key = var.ssh_key == "" ? file("~/.ssh/id_rsa.pub") : var.ssh_key
}

############### Storage Location Base #################
resource "aws_s3_bucket" "cdp" {
  bucket = "${var.owner}-cdp-bucket"

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