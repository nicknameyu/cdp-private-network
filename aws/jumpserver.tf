######################## CDP VPC Jump Server ########################
module "spoke-jump-server" {
  source                  = "github.com/nicknameyu/terraform-modules/aws/modules/aws_ubuntu_instance"
  name                    = "${var.owner}-spoke-jump"
  vpc_id                  = module.hub-spoke.spoke_vpc_id
  subnet_id               = module.hub-spoke.spoke_private_subnets["pvt_subnet_1"].subnet_id
  enable_pub_ip           = false
  key_name                = module.env_prerequisites.ssh_key_name

  sg_ingress_rules        = {
                              ssh =  {
                                from_port        = 22
                                to_port          = 22
                                ip_protocol      = "TCP"
                                cidr_block       = "0.0.0.0/0"
                              }
                            }
  sg_egress_rules         = {
                              internet = {
                                from_port        = -1
                                to_port          = -1
                                ip_protocol      = "-1"
                                cidr_block       = "0.0.0.0/0"
                              }
                            }
  private_key             = file(var.ssh_key.private_rsa_key_path)
  tags                    = var.tags

}
output "cdp_jump_private_ip" {
  value = module.spoke-jump-server.private_ip
}


module "windows-jump-server" {
  count                   = var.create_windows_jumpserver ? 1:0
  source                  = "github.com/nicknameyu/terraform-modules/aws/modules/aws_windows_instance"
  name                    = "${var.owner}-win-jump"
  vpc_id                  = module.hub-spoke.hub_vpc_id
  subnet_id               = module.hub-spoke.hub_public_subnets["pub_subnet_1"].subnet_id
  enable_pub_ip           = true
  key_name                = module.env_prerequisites.ssh_key_name

  sg_ingress_rules        = {
                              ssh =  {
                                from_port        = 3389
                                to_port          = 3389
                                ip_protocol      = "TCP"
                                cidr_block       = "0.0.0.0/0"
                              }
                            }
  sg_egress_rules         = {
                              internet = {
                                from_port        = -1
                                to_port          = -1
                                ip_protocol      = "-1"
                                cidr_block       = "0.0.0.0/0"
                              }
                            }
  private_key             = file(var.ssh_key.private_rsa_key_path)
  tags                    = var.tags
}

output "windows_jumpserver" {
  value = var.create_windows_jumpserver ? module.windows-jump-server[0].connect_info : null
}