locals {
  dns_server_ingress_rules = {
                              ssh =  {
                                from_port        = 22
                                to_port          = 22
                                ip_protocol      = "TCP"
                                cidr_block       = "0.0.0.0/0"
                              }
                              CDP_DNS = {
                                from_port        = 53
                                to_port          = 53
                                ip_protocol      = "UDP"
                                cidr_block       = var.cdp_vpc.cidr
                              }
                              HUB_DNS = {
                                from_port        = 53
                                to_port          = 53
                                ip_protocol      = "UDP"
                                cidr_block       = var.core_vpc.cidr
                              }
                            }
                            
  dns_server_egress_rules = {
                              internet = {
                                from_port        = -1
                                to_port          = -1
                                ip_protocol      = "-1"
                                cidr_block       = "0.0.0.0/0"
                              }
                            }
}
## Hub Jump Server
module "hub-jump-server" {
  source                  = "./modules/aws_ubuntu_instance"
  name                    = "${var.owner}-hub-jump"
  vpc_id                  = aws_vpc.core.id
  subnet_id               = aws_subnet.core["core"].id
  enable_pub_ip           = true
  key_name                = module.env_prerequisites.ssh_key_name
  bootstrap_scripts       = [ 
                              file("./scripts/install_aws_cli.sh"), 
                              file("./scripts/install_kubectl.sh"),
                              templatefile("./scripts/install_bind9.sh", {
                                DNS_RESOLVER_IP = tolist(aws_route53_resolver_endpoint.cdp.ip_address)[0].ip
                                REGION          = var.region
                              }) 
                            ]

  sg_ingress_rules        = local.dns_server_ingress_rules
  sg_egress_rules         = local.dns_server_egress_rules

  private_key             = file(var.ssh_key.private_rsa_key_path)

  tags                    = var.tags
}
output "dns_server_private_ip" {
  value = module.hub-jump-server.private_ip
}
output "dns_server_public_ip" {
  value = module.hub-jump-server.public_ip
}
######################## CDP VPC Jump Server ########################
module "cdp-jump-server" {
  source                  = "./modules/aws_ubuntu_instance"
  name                    = "${var.owner}-cdp-jump"
  vpc_id                  = aws_vpc.cdp.id
  subnet_id               = aws_subnet.cdp["subnet1"].id
  key_name                = module.env_prerequisites.ssh_key_name
  bootstrap_scripts       = [ file("./scripts/install_aws_cli.sh"), file("./scripts/install_kubectl.sh") ]
  tags                    = var.tags
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
  depends_on              = [ aws_networkfirewall_firewall.fw ]
}
output "cdp_jump_private_ip" {
  value = module.cdp-jump-server.private_ip
}
# ################### Windows Server ################
data "aws_ami" "windows" {
     most_recent = true
     filter {
        name   = "name"
        values = ["Windows_Server-2022-English-Full-Base-*"]
 }
     filter {
       name   = "virtualization-type"
       values = ["hvm"]
 }
     owners = ["801119661308"] # Canonical
 }
resource "aws_security_group" "win" {
  count  = var.create_windows_jumpserver ? 1:0
  name   = "${var.owner}-win-sg"
  vpc_id = aws_vpc.core.id

  ingress {
    description      = "RDP"
    from_port        = 3389
    to_port          = 3389
    protocol         = "TCP"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    description      = "DNS"
    from_port        = 53
    to_port          = 53
    protocol         = "UDP"
    cidr_blocks      = ["10.0.0.0/8"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  tags   = var.tags
}
resource "aws_eip" "win" {
  count             = var.create_windows_jumpserver ? 1:0
  network_interface = aws_network_interface.win[0].id
  domain            = "vpc"
  tags = merge({
    Name = "${var.owner}-win-eip"
  }, var.tags)
}

resource "aws_network_interface" "win" {
  count           = var.create_windows_jumpserver ? 1:0
  subnet_id       = aws_subnet.core["core"].id
  security_groups = [ aws_security_group.win[0].id ]

  tags = merge({
    Name = "${var.owner}-win-nic"
  }, var.tags)
}

resource "aws_instance" "win" {
  count         = var.create_windows_jumpserver ? 1:0
  ami           = data.aws_ami.windows.id
  instance_type = "t2.large"
  key_name      = module.env_prerequisites.ssh_key_name
  network_interface {
    network_interface_id = aws_network_interface.win[0].id
    device_index         = 0
  }
  get_password_data = true
  credit_specification {
    cpu_credits = "unlimited"
  }
  tags = merge({
    Name = "${var.owner}-win"
  }, var.tags)
  lifecycle {
    ignore_changes = [ ami ]
  }
 }
output "win_jumpserver" {
  value = !var.create_windows_jumpserver ? null : {
                                                    public_ip = aws_eip.win[0].public_ip
                                                    username  = "Administrator"
                                                    password  = rsadecrypt(aws_instance.win[0].password_data, file(var.ssh_key.private_rsa_key_path))
                                                  }
}
