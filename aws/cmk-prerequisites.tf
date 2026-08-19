
module "cmk" {
  source                      = "github.com/nicknameyu/cdp-prerequisite-module/aws/cmk-prerequisites"
  key_alias                   = "${var.owner}-cdp-key"
  cross_account_role_arn      = module.cdp_cross_account_role.xaccount_role_arn
  s3_bucket_id                = var.cdp_bucket_name
  cdp_prerequisite_role_names = [
    module.env_prerequisites.cdp_role_names.idbroker,
    module.env_prerequisites.cdp_role_names.data_admin,
    module.env_prerequisites.cdp_role_names.logger,
    module.env_prerequisites.cdp_role_names.ranger,
  ]

  tags = merge( var.tags, {owner = "${var.owner}"})
  depends_on = [ module.env_prerequisites ]
}
output "kms_key_arn" {
  value = module.cmk.kms_key_arn
}
