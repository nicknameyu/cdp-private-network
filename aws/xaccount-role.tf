
module "cdp_cross_account_role" {
  source                    = "github.com/nicknameyu/cdp-prerequisite-module/aws/xaccount-role"
  create_role               = var.cross_account_role == null ? true : false
  cross_account_role_name   = var.cross_account_role == null ? "${var.owner}-cdp-xacct-role" : var.cross_account_role
  cdp_xaccount_external_id  = var.cross_account_role == null ? var.cdp_xaccount_external_id : null
  cdp_xaccount_account_id   = "387553343826"
  cross_account_policy_name = "${var.owner}-cdp-xacct-policy"
  tags                      = merge(var.tags, {owner = "${var.owner}"})
}
