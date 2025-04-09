
resource "aws_key_pair" "ssh_pub" {
  key_name   = "${var.owner}-ssh-key"
  public_key = file(var.ssh_key.public_key_path)
  tags        = var.tags
}

############### Storage Location Base #################
resource "aws_s3_bucket" "cdp" {
  bucket = var.cdp_bucket_name == null ? "${var.owner}-cdp-poc-bucket" : var.cdp_bucket_name
  force_destroy  = true

  tags = merge({
    Name        = "${var.owner}-cdp-bucket"
  }, var.tags)
}

resource "aws_s3_object" "folders" {
  for_each = toset(["data", "logs", "backups", "ranger"])
  bucket = aws_s3_bucket.cdp.id
  key    = "${each.value}/"
  source = "/dev/null"
  tags   = var.tags
}

output "storage_locations" {
  value = [for x in aws_s3_object.folders : "${aws_s3_bucket.cdp.id}/${x.key}" ]
}

############### KMS Key ##############
resource "aws_kms_key" "cdp" {
  description             = "KMS key for CDP"
  policy = replace(
    replace(file("./policies/aws-cdp-kms-key-policy.json"), "$${AWS_ACCOUNT_ID}", data.aws_caller_identity.current.account_id),
    "$${CDP_CROSS_ACCOUNT_ROLE_ARN}", (var.cross_account_role == null ? aws_iam_role.cross_account[0].arn : data.aws_iam_role.cross_account[0].arn))
  tags        = var.tags
}
resource "aws_kms_alias" "cdp" {
  name          = var.cmk_key_name == null ? "alias/${var.owner}-cdp-key" : "alias/${var.cmk_key_name}"
  target_key_id = aws_kms_key.cdp.key_id
}
output "kms_key" {
  value = {
    key_arn = aws_kms_key.cdp.arn
    key_alias_arn = aws_kms_alias.cdp.arn
  }
}
