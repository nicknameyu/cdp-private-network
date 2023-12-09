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
}

output "cdp_jump_private_ip" {
  value = aws_network_interface.cdp-jump.private_ip
}