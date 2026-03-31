
module "data-services-prerequisites" {
    source             = "github.com/nicknameyu/cdp-prerequisite-module/aws/data-services-prerequisites"

    xaccount_role_name = element(split("/", module.cdp_cross_account_role.xaccount_role_arn), length(split("/", module.cdp_cross_account_role.xaccount_role_arn)) - 1)
    cdp_bucket_name    = replace(module.env_prerequisites.s3_bucket_id, "arn:aws:s3:::", "")
    idbroker_role_name = module.env_prerequisites.cdp_role_names.idbroker
    log_role_name      = module.env_prerequisites.cdp_role_names.logger
    policy_prefix      = "${var.owner}"

    # When default permission is applied, most of below data service specific policies are not required
    enable_dw          = var.default_permission ? false : var.enable_dw
    enable_de          = var.default_permission ? false : var.enable_de

    # CAI is kind of special, cause CAI backup/restore needs some special permissions which are not even included in default permissions.
    enable_ai          = var.enable_ai
    enable_df          = var.default_permission ? false : var.enable_df
    enable_cmk         = var.default_permission ? false : var.enable_cmk
    create_eks_role    = var.default_permission ? false : var.create_eks_role
    liftie_role_stack_name = var.create_eks_role ? "${var.owner}-liftie-role-pair" : null


    tags               = merge(var.tags, {owner = "${var.owner}"})
}
