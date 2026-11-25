
module "cdp_cross_account_role" {
  source                    = "github.com/nicknameyu/cdp-prerequisite-module/aws/xaccount-role"
  create_role               = var.create_cross_account_role
  cross_account_role_name   = var.cross_account_role == null ? "${var.owner}-cdp-xacct-role" : var.cross_account_role
  cdp_xaccount_external_id  = var.cdp_xaccount_external_id
  cdp_xaccount_account_id   = var.cdp_xaccount_account_id
  cross_account_policy_name = "${var.owner}-cdp-xacct-policy"
  default_permission        = var.default_permission
  tags                      = merge(var.tags, {owner = "${var.owner}"})
}
