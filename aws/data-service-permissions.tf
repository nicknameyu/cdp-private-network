
module "data-services-prerequisites" {
    source             = "github.com/nicknameyu/cdp-prerequisite-module/aws/data-services-prerequisites"

    xaccount_role_name = element(split("/", module.cdp_cross_account_role.xaccount_role_arn), length(split("/", module.cdp_cross_account_role.xaccount_role_arn)) - 1)
    cdp_bucket_name    = replace(module.env_prerequisites.s3_bucket_id, "arn:aws:s3:::", "")
    idbroker_role_name = module.env_prerequisites.cdp_role_names.idbroker
    log_role_name      = module.env_prerequisites.cdp_role_names.logger
    policy_prefix      = "${var.owner}"

    enable_dw          = var.enable_dw
    enable_de          = var.enable_de
    enable_ai          = var.enable_ai
    enable_df          = var.enable_df
    enable_cmk         = var.enable_cmk
    create_eks_role    = var.create_eks_role
    liftie_role_stack_name = var.create_eks_role ? "${var.owner}-liftie-role-pair" : null


    tags               = merge(var.tags, {owner = "dyu"})
}
