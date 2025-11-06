
module "env_prerequisites" {
    source = "github.com/nicknameyu/cdp-prerequisite-module/aws/env-prerequisites"
    cdp_bucket_name = var.cdp_bucket_name == null ? "${var.owner}-cdp-poc-bucket" : var.cdp_bucket_name
    region          = var.region
    role_names = {
        idbroker       = "${var.owner}-IDBROKER"
        datalake_admin = "${var.owner}-DATALAKE_ADMIN_ROLE"
        logger         = "${var.owner}-LOG_ROLE"
        ranger         = "${var.owner}-RANGER_ROLE"
    }
    policy_names = {
      cross_account_policy        = "${var.owner}-cross-account-policy"
      ec2-kms-policy              = "${var.owner}-ec2-kms-policy"
      sse-kms-read-only-policy    = "${var.owner}-sse-kms-read-only-policy"
      sse-kms-read-write-policy   = "${var.owner}-sse-kms-read-write-policy"
      idbroker-assume-role-policy = "${var.owner}-idbroker-assume-role-policy"
      log-policy                  = "${var.owner}-log-policy"
      datalake-restore-policy     = "${var.owner}-datalake-restore-policy"
      backup-policy               = "${var.owner}-backup-policy"
      ranger-audit-s3-policy      = "${var.owner}-ranger-audit-s3-policy"
      bucket-access-policy        = "${var.owner}-bucket-access-policy"
      datalake-backup-policy      = "${var.owner}-datalake-backup-policy"
      datalake-admin-s3-policy    = "${var.owner}-datalake-admin-s3-policy"
    }
    ssh_key_name                  = "${var.owner}-ssh-key"
    ssh_key                       = file("${var.ssh_key.public_key_path}")
    instance_profile_names        = {
      data_access                 = "${var.owner}-data-access-instance-profile"
      log_access                  = "${var.owner}-log-access-instance-profile"
    }
    tags                          = merge({ owner = var.owner }, var.tags)
}
output "storage_locations" {
  value = module.env_prerequisites.storage_locations
}
output "cdp_roles" {
  value = {
    instance_profiles = module.env_prerequisites.instance_profiles
    cdp_roles = module.env_prerequisites.cdp_role_names
  }
}
