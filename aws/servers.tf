data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

#####################Core VPC Jump Server ###################
resource "aws_security_group" "core-jump" {
  name   = "${var.owner}-core-jump-sg"
  vpc_id = aws_vpc.core.id

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "TCP"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    description      = "DNS"
    from_port        = 53
    to_port          = 53
    protocol         = "UDP"
    cidr_blocks      = [var.cdp_vpc.cidr, var.core_vpc.cidr]
  }
  ingress {
    description      = "VNC"
    from_port        = 5901
    to_port          = 5901
    protocol         = "TCP"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  tags   = {
    owner = var.owner
  }
}
resource "aws_eip" "core-jump" {
  network_interface = aws_network_interface.core-jump.id
  domain   = "vpc"
  tags = {
    Name = "${var.owner}-core-jump-eip"
    owner = var.owner
  }
}
output "core_jump_public_ip" {
  value = aws_eip.core-jump.public_ip
}
output "core_jump_private_ip" {
  value = aws_network_interface.core-jump.private_ip
}

resource "aws_network_interface" "core-jump" {
  subnet_id   = aws_subnet.core["core"].id
  security_groups = [ aws_security_group.core-jump.id ]

  tags = {
    Name = "${var.owner}-core-jump-nic"
    owner = var.owner
  }
}
locals {
  named_conf         = replace(
                          replace(file("conf/named.conf"), "$${REGION}", var.region), 
                          "$${DNS_RESOLVER_IP}", tolist(aws_route53_resolver_endpoint.cdp.ip_address)[0].ip)
  named_conf_options = file("conf/named.conf.options")
}

# replace(file("./conf/named.conf"), "$${AKS_PRIVATEDNS_ZONE}", "${azurerm_private_dns_zone.aks.name}"),
#                                   "$${PG_PRIVATEDNS_ZONE}", "${azurerm_private_dns_zone.pg_flx.name}"
                                
resource "aws_instance" "core-jump" {
  ami           =  data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.ssh_pub.key_name
  depends_on    = [ aws_networkfirewall_firewall.fw ]
  connection {
    type = "ssh"
    user = "ubuntu"
    private_key = file(var.ssh_key.private_rsa_key_path)
    host        = aws_eip.core-jump.public_ip
  }
  provisioner "file" {
    content     = local.named_conf
    destination = "/tmp/named.conf"
  }
  provisioner "file" {
    source      = "conf/named.conf.options"
    destination = "/tmp/named.conf.options"
  }
  provisioner "file" {
    source      = var.ssh_key.private_rsa_key_path
    destination = "/home/ubuntu/.ssh/id_rsa"
  }
  user_data     = <<EOF
#!/usr/bin/bash
chown ubuntu:ubuntu /home/ubuntu/.ssh/id_rsa
chmod 600 /home/ubuntu/.ssh/id_rsa
echo "################ DNS Configuration ##################"
sudo apt install bind9 -y
sudo apt install dnsutils -y
sudo mv /etc/bind/named.conf.options /etc/bind/named.conf.options.backup
sudo mv /etc/bind/named.conf /etc/bind/named.conf.backup
sudo mv /tmp/named.conf /etc/bind/named.conf
sudo mv /tmp/named.conf.options /etc/bind/named.conf.options
sudo chown root:bind /etc/bind/named.conf.options
sudo chown root:bind /etc/bind/named.conf
sudo chmod 644 /etc/bind/named.conf.options
sudo chmod 644 /etc/bind/named.conf
sudo systemctl restart bind9.service
EOF

  network_interface {
    network_interface_id = aws_network_interface.core-jump.id
    device_index         = 0
  }

  credit_specification {
    cpu_credits = "unlimited"
  }
  tags = {
    Name = "${var.owner}-core-jump"
    owner = var.owner
  }
  lifecycle {
    ignore_changes = [ ami ]
  }
}


######################## CDP VPC Jump Server ########################
resource "aws_security_group" "cdp-jump" {
  name   = "${var.owner}-cdp-jump-sg"
  vpc_id = aws_vpc.cdp.id

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "TCP"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  tags   = {
    owner = var.owner
  }
}

resource "aws_network_interface" "cdp-jump" {
  subnet_id   = aws_subnet.cdp["subnet1"].id
  security_groups = [ aws_security_group.cdp-jump.id ]

  tags = {
    Name = "${var.owner}-cdp-jump-nic"
    owner = var.owner
  }
}

resource "aws_instance" "cdp-jump" {
  ami           =  data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  user_data = <<EOF
#!/bin/bash
echo "Copying the SSH Key to the server"
echo -e "${aws_key_pair.ssh_pub.public_key}" >> /home/ubuntu/.ssh/authorized_keys
echo -e "${file(var.ssh_key.private_rsa_key_path)}" > /home/ubuntu/.ssh/id_rsa
chown ubuntu:ubuntu /home/ubuntu/.ssh/id_rsa
chmod 600 /home/ubuntu/.ssh/id_rsa
EOF

  network_interface {
    network_interface_id = aws_network_interface.cdp-jump.id
    device_index         = 0
  }

  credit_specification {
    cpu_credits = "unlimited"
  }
  tags = {
    Name = "${var.owner}-cdp-jump"
    owner = var.owner
  }
  lifecycle {
    ignore_changes = [ ami ]
  }
}

output "cdp_jump_private_ip" {
  value = aws_network_interface.cdp-jump.private_ip
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
  tags   = {
    owner = var.owner
  }
}
resource "aws_eip" "win" {
  count             = var.create_windows_jumpserver ? 1:0
  network_interface = aws_network_interface.win[0].id
  domain            = "vpc"
  tags = {
    Name = "${var.owner}-win-eip"
    owner = var.owner
  }
}

resource "aws_network_interface" "win" {
  count           = var.create_windows_jumpserver ? 1:0
  subnet_id       = aws_subnet.core["core"].id
  security_groups = [ aws_security_group.win[0].id ]

  tags = {
    Name = "${var.owner}-win-nic"
    owner = var.owner
  }
}

resource "aws_instance" "win" {
  count         = var.create_windows_jumpserver ? 1:0
  ami           = data.aws_ami.windows.id
  instance_type = "t2.large"
  key_name      = aws_key_pair.ssh_pub.key_name
  network_interface {
    network_interface_id = aws_network_interface.win[0].id
    device_index         = 0
  }
  get_password_data = true
  credit_specification {
    cpu_credits = "unlimited"
  }
  tags = {
    Name = "${var.owner}-win"
    owner = var.owner
  }
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
