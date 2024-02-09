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

resource "aws_instance" "core-jump" {
  ami           =  data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  user_data = <<EOF
#!/bin/bash
echo "Copying the SSH Key to the server"
echo -e "${aws_key_pair.ssh_pub.public_key}" >> /home/ubuntu/.ssh/authorized_keys
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

################### Windows Server ################
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
resource "aws_security_group" "dns" {
  name   = "${var.owner}-dns-sg"
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
resource "aws_eip" "dns" {
  network_interface = aws_network_interface.dns.id
  domain   = "vpc"
  tags = {
    Name = "${var.owner}-dns-eip"
    owner = var.owner
  }
}
output "dns_public_ip" {
  value = aws_eip.dns.public_ip
}
output "dns_private_ip" {
  value = aws_network_interface.dns.private_ip
}

resource "aws_network_interface" "dns" {
  subnet_id   = aws_subnet.core["core"].id
  security_groups = [ aws_security_group.dns.id ]

  tags = {
    Name = "${var.owner}-dns-nic"
    owner = var.owner
  }
}

resource "aws_instance" "dns" {
  ami = data.aws_ami.windows.id
  instance_type = "t2.micro"
  key_name = aws_key_pair.ssh_pub.key_name
  network_interface {
    network_interface_id = aws_network_interface.dns.id
    device_index         = 0
  }
  get_password_data = true
  credit_specification {
    cpu_credits = "unlimited"
  }
  tags = {
    Name = "${var.owner}-dns"
    owner = var.owner
  }
  lifecycle {
    ignore_changes = [ ami ]
  }
 }

 output "dns_server_password" {
   value = rsadecrypt(aws_instance.dns.password_data, file(var.ssh_key.private_rsa_key_path))
 }