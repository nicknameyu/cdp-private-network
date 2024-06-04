############### Cross account role #############
resource "aws_iam_policy" "cross_account" {
  name        = "${var.owner}-poc-policy"
  path        = "/"
  description = "${upper(var.owner)} POC policy"
  policy      = var.default_permission ? file("./policies/cdp-cross-account-policy.json") : file("./policies/cdp-cross-account-reduced-policy.json")
  tags        = {
    owner = var.owner
  }
}
resource "aws_iam_policy" "ec2kms" {
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

  tags = {
    owner = var.owner
  }
}
locals {
  cross_account_role = var.cross_account_role == null ? aws_iam_role.cross_account[0].name : var.cross_account_role
}
data "aws_iam_role" "cross_account" {
  count = var.cross_account_role == null ? 0:1
  name  = var.cross_account_role
}
resource "aws_iam_role_policy_attachment" "default" {
  count = var.default_permission ? 1:0
  role = local.cross_account_role
  policy_arn = aws_iam_policy.cross_account.arn
}
resource "aws_iam_role_policy_attachment" "ec2kms" {
  role = local.cross_account_role
  policy_arn = aws_iam_policy.ec2kms.arn
}

############# Reduced Permission ################
resource "aws_cloudformation_stack" "liftie" {
  count         = var.default_permission ? 0:1
  name          = "${var.owner}-liftie-role-pair"
  capabilities  = ["CAPABILITY_NAMED_IAM"]
  template_body = file("./cf/aws-liftie-role-pair.yaml")
  parameters    = {
    TelemetryLoggingBucket  = aws_s3_bucket.cdp.tags.Name
    TelemetryLoggingRootDir = "cluster-logs"
    TelemetryLoggingEnabled = "true"
  }
}

locals {
  liftie_policy_raw = file("./policies/aws-ds-restricted-policy-1.json")
  liftie_policy_1   = replace(local.liftie_policy_raw, "$${YOUR-ACCOUNT-ID}", data.aws_caller_identity.current.account_id)
  liftie_policy_2   = replace(local.liftie_policy_1, "$${YOUR-IAM-ROLE-NAME}", local.cross_account_role)
  liftie_policy_3   = replace(local.liftie_policy_2, "$${YOUR-IDBROKER-ROLE-NAME}", "${var.owner}-IDBROKER")
  liftie_policy_4   = replace(local.liftie_policy_3, "$${YOUR-LOG-ROLE-NAME}", "${var.owner}-LOG_ROLE")
  liftie_policy_5   = replace(local.liftie_policy_4, "$${YOUR-KMS-CUSTOMER-MANAGED-KEY-ARN}", aws_kms_key.cdp.arn)
  liftie_min_policy = replace(local.liftie_policy_5, "$${YOUR-SUBNET-REGION}", var.region)
  
  # DE policy cannot be put into on policy file. Using two policy file for DE permissions.
  reduced_policies  = {
    de1       = {
      name         = "${var.owner}-de-reduced-policy-1"
      description  = "${upper(var.owner)} reduced policy for Data Engineering part 1"
      policy       = file("./policies/aws-de-restricted-policy-part1.json")
    }
    de2       = {
      name         = "${var.owner}-de-reduced-policy-2"
      description  = "${upper(var.owner)} reduced policy for Data Engineering part 2"
      policy       = file("./policies/aws-de-restricted-policy-part2.json")
    }

    # Liftie policy cannot be put into on policy file. Using two policy file for Liftie permissions.
    liftie1 = {
      name         = "${var.owner}-liftie-reduced-policy1"
      description  = "${upper(var.owner)} reduced policy for Liftie1"
      policy       = local.liftie_min_policy
    }
    liftie2 = {
      name         = "${var.owner}-liftie-reduced-policy2"
      description  = "${upper(var.owner)} reduced policy for Liftie2"
      policy       = replace(file("./policies/aws-ds-restricted-policy-2.json"), "$${YOUR-ACCOUNT-ID}", data.aws_caller_identity.current.account_id)
    }
    liftie_cmk = {
      name         = "${var.owner}-liftie-cmk-reduced-policy"
      description  = "${upper(var.owner)} reduced policy for Liftie with CMK"
      policy       = replace(replace(file("./policies/aws-liftie-cmk-reduced-policy.json"),
                               "$${YOUR-ACCOUNT-ID}", data.aws_caller_identity.current.account_id),
                        "$${CDP-CROSSACCOUNT-ROLE}", local.cross_account_role)
    }
    dw         = {
      name        = "${var.owner}-dw-reduced-policy"
      description = "${upper(var.owner)} reduced policy for Data Warehouse"
      policy      = replace(replace(file("./policies/aws-dw-reduced-permissions.json"),
                               "$${ACCOUNT_ID}", data.aws_caller_identity.current.account_id),
                        "$${DATALAKE_BUCKET}", aws_s3_bucket.cdp.tags.Name)
    }
    df         = {
      name        = "${var.owner}-df-reduced-policy"
      description = "${upper(var.owner)} reduced policy for Data Flow"
      policy      = replace(
                            replace(file("./policies/aws-df-reduced-policy.json"), 
                                    "$${YOUR-ACCOUNT-ID}", 
                                    data.aws_caller_identity.current.account_id ), 
                            "$${YOUR-IDBROKER-ROLE-NAME}", aws_iam_role.idbroker.name)
    }
    # ML Policy is not required if DE/DF policy is outstanding. But still keep the ML policy file in the policy folder for future testing.
    # ml         = {
    #   name        = "${var.owner}-ml-reduced-policy"
    #   description = "${upper(var.owner)} reduced policy for Machine Learning"
    #   policy      = replace(replace(file("./policies/aws-ml-restricted-policy.json"),
    #                               "$${YOUR-ACCOUNT-ID}", data.aws_caller_identity.current.account_id),
    #                         "$${YOUR-IAM-ROLE-NAME}",
    #                         local.cross_account_role)
    # }
  }
}
resource "aws_iam_policy" "reduced" {
  for_each = local.reduced_policies
  name        = each.value.name
  path        = "/"
  description = each.value.description
  policy      = each.value.policy
  tags        = {
    owner = var.owner
  }
}

resource "aws_iam_role_policy_attachment" "reduced_liftie1" {
  for_each = var.default_permission ? {} : aws_iam_policy.reduced
  role = local.cross_account_role
  policy_arn = each.value.arn
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