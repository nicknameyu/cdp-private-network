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

}
output "cdp_jump_private_ip" {
  value = module.spoke-jump-server.private_ip
}