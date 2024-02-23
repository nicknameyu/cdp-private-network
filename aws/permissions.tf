############### Cross account role #############
resource "aws_iam_policy" "cross_account" {
  count       = var.cross_account_role == null ? 1:0
  name        = "${var.owner}-poc-policy"
  path        = "/"
  description = "${upper(var.owner)} POC policy"
  policy      = file("./policies/cdp-cross-account-policy.json")
  tags        = {
    owner = var.owner
  }
}
resource "aws_iam_policy" "ec2kms" {
  count       = var.cross_account_role == null ? 1:0
  name        = "${var.owner}-aws-cdp-ec2-kms-policy"
  path        = "/"
  description = "aws-cdp-ec2-kms-policy"
  policy      = file("./policies/aws-cdp-ec2-kms-policy.json")
  tags        = {
    owner = var.owner
  }
}

resource "aws_iam_role" "cross_account" {
  count               = var.cross_account_role == null ? 1:0
  name                = "${var.owner}-cdp-poc"
  assume_role_policy  = replace(file("./policies/cdp-cross-account-trust-policy.json"), "$${PRINCIPAL_ARN_KEY_WORD}", var.aws_sso_user_arn_keyword)
  managed_policy_arns = [
    aws_iam_policy.cross_account[0].arn,
    aws_iam_policy.ec2kms[0].arn
  ]

  tags = {
    owner = var.owner
  }
}

data "aws_iam_role" "cross_account" {
  count = var.cross_account_role == null ? 0:1
  name = var.cross_account_role
}

############### IAM ROLES ###################
# KMS policies
resource "aws_iam_policy" "kms_ro" {
  name        = "${var.owner}-aws-cdp-sse-kms-read-only-policy"
  path        = "/"
  description = "aws-cdp-sse-kms-read-only-policy"

  policy = replace(file("./policies/aws-cdp-sse-kms-read-only-policy.json"), "$${KEY_ARN}", aws_kms_alias.cdp.arn)
  tags = {
    owner = var.owner
  }
}
resource "aws_iam_policy" "kms_rw" {
  name        = "${var.owner}-aws-cdp-sse-kms-read-write-policy"
  path        = "/"
  description = "aws-cdp-sse-kms-read-write-policy"

  policy = replace(file("./policies/aws-cdp-sse-kms-read-write-policy.json"), "$${KEY_ARN}", aws_kms_alias.cdp.arn)
  tags = {
    owner = var.owner
  }
}
# IDBROKER role
resource "aws_iam_policy" "assume" {
  name        = "${var.owner}-aws-cdp-idbroker-assume-role-policy"
  path        = "/"
  description = "aws-cdp-idbroker-assume-role-policy"

  policy = file("./policies/aws-cdp-idbroker-assume-role-policy.json")
  tags = {
    owner = var.owner
  }
}
resource "aws_iam_policy" "log" {
  name        = "${var.owner}-aws-cdp-log-policy"
  path        = "/"
  description = "aws-cdp-log-policy"

  policy = replace(
    replace(file("./policies/aws-cdp-log-policy.json"), "$${LOGS_BUCKET_ARN}", aws_s3_bucket.cdp.arn), 
    "$${LOGS_LOCATION_BASE}", 
    "${aws_s3_bucket.cdp.arn}/${aws_s3_object.folders["logs"].key}") 
  tags = {
    owner = var.owner
  }
}

resource "aws_iam_role" "idbroker" {
  name                = "${var.owner}-IDBROKER"
  assume_role_policy  = file("./policies/aws-cdp-ec2-role-trust-policy.json")
  managed_policy_arns = [aws_iam_policy.assume.arn, aws_iam_policy.log.arn]

  tags = {
    owner = var.owner
  }
}

# LOG ROLE
resource "aws_iam_policy" "restore" {
  name        = "${var.owner}-aws-datalake-restore-policy"
  path        = "/"
  description = "aws-datalake-restore-policy"

  policy      = replace(file("./policies/aws-datalake-restore-policy.json"), "$${CDP_BUCKET_ARN}", 
    "${aws_s3_bucket.cdp.arn}") 
  tags = {
    owner = var.owner
  }
}
resource "aws_iam_policy" "cdp_backup" {
  name        = "${var.owner}-aws-cdp-backup-policy"
  path        = "/"
  description = "aws-cdp-backup-policy"

  policy      = replace(file("./policies/aws-cdp-backup-policy.json"), "$${BACKUP_LOCATION_BASE}", 
                        "${aws_s3_bucket.cdp.arn}/${aws_s3_object.folders["backups"].key}") 
  tags        = {
    owner = var.owner
  }
}

resource "aws_iam_role" "log" {
  name                = "${var.owner}-LOG_ROLE"
  assume_role_policy  = file("./policies/aws-cdp-ec2-role-trust-policy.json")
  managed_policy_arns = [
    aws_iam_policy.restore.arn, 
    aws_iam_policy.log.arn, 
    aws_iam_policy.cdp_backup.arn,
    aws_iam_policy.kms_rw.arn
    ]

  tags = {
    owner = var.owner
  }
}

# RANGER_AUDIT_ROLE
resource "aws_iam_policy" "ranger" {
  name        = "${var.owner}-aws-cdp-ranger-audit-s3-policy"
  path        = "/"
  description = "aws-cdp-ranger-audit-s3-policy"

  policy = replace(file("./policies/aws-cdp-ranger-audit-s3-policy.json"), "$${CDP_BUCKET_ARN}", 
    aws_s3_bucket.cdp.arn) 
  tags = {
    owner = var.owner
  }
}
resource "aws_iam_policy" "bkt_access" {
  name        = "${var.owner}-aws-cdp-bucket-access-policy"
  path        = "/"
  description = "aws-cdp-bucket-access-policy"

  policy = replace(file("./policies/aws-cdp-bucket-access-policy.json"), "$${CDP_BUCKET_ARN}", 
    aws_s3_bucket.cdp.arn) 
  tags = {
    owner = var.owner
  }
}
resource "aws_iam_policy" "dl_backup" {
  name        = "${var.owner}-aws-datalake-backup-policy"
  path        = "/"
  description = "aws-datalake-backup-policy"

  policy = replace(file("./policies/aws-datalake-backup-policy.json"), "$${BACKUP_LOCATION_BASE}", 
     "${aws_s3_bucket.cdp.arn}/${aws_s3_object.folders["backups"].key}") 
  tags = {
    owner = var.owner
  }
}

resource "aws_iam_role" "ranger" {
  name = "${var.owner}-RANGER_AUDIT_ROLE"
  assume_role_policy = replace(file("./policies/aws-cdp-idbroker-role-trust-policy.json"), "$${IDBROKER_ROLE_ARN}", aws_iam_role.idbroker.arn)
  managed_policy_arns = [
    aws_iam_policy.ranger.arn,
    aws_iam_policy.bkt_access.arn,
    aws_iam_policy.dl_backup.arn,
    aws_iam_policy.restore.arn,
    aws_iam_policy.kms_rw.arn
    ]

  tags = {
    owner = var.owner
  }
}

# DATALAKE_ADMIN_ROLE
resource "aws_iam_policy" "dl_admin" {
  name        = "${var.owner}-aws-cdp-datalake-admin-s3-policy"
  path        = "/"
  description = "aws-cdp-datalake-admin-s3-policy"

  policy = replace(file("./policies/aws-cdp-datalake-admin-s3-policy.json"), "$${STORAGE_LOCATION_BASE}", 
    "${aws_s3_bucket.cdp.arn}/data") 
  tags = {
    owner = var.owner
  }
}
resource "aws_iam_role" "dl_admin" {
  name = "${var.owner}-DATALAKE_ADMIN_ROLE"
  assume_role_policy = replace(file("./policies/aws-cdp-idbroker-role-trust-policy.json"), "$${IDBROKER_ROLE_ARN}", aws_iam_role.idbroker.arn)
  managed_policy_arns = [
    aws_iam_policy.dl_admin.arn,
    aws_iam_policy.bkt_access.arn,
    aws_iam_policy.dl_backup.arn,
    aws_iam_policy.restore.arn,
    aws_iam_policy.kms_rw.arn
    ]

  tags = {
    owner = var.owner
  }
}

output "roles" {
  value = [
    aws_iam_role.idbroker.name,
    aws_iam_role.log.name,
    aws_iam_role.dl_admin.name,
    aws_iam_role.ranger.name]
}

############# Instance Profiles #############
resource "aws_iam_instance_profile" "data_access" {
  name = "${var.owner}-data-access-instance-profile"
  role = aws_iam_role.idbroker.name
  tags = {
    owner = var.owner
  }
}

resource "aws_iam_instance_profile" "log_access" {
  name = "${var.owner}-log-access-instance-profile"
  role = aws_iam_role.log.name
  tags = {
    owner = var.owner
  }
}
output "Profiles" {
  value = [aws_iam_instance_profile.data_access.name, aws_iam_instance_profile.log_access.name]
  
}