data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = [var.ami_filter]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = [var.ami_owner] # Canonical
}

## Security group
resource "aws_security_group" "instance" {
  name   = "${var.name}-sg"
  vpc_id = var.vpc_id
  tags   = var.tags
}

resource "aws_vpc_security_group_ingress_rule" "instance" {
  for_each          = var.sg_ingress_rules
  description       = each.key
  security_group_id = aws_security_group.instance.id
  cidr_ipv4         = each.value.cidr_block
  from_port         = each.value.from_port
  ip_protocol       = each.value.ip_protocol
  to_port           = each.value.to_port
}

resource "aws_vpc_security_group_egress_rule" "instance" {
  for_each          = var.sg_egress_rules
  description       = each.key
  security_group_id = aws_security_group.instance.id
  cidr_ipv4         = each.value.cidr_block
  from_port         = each.value.from_port
  ip_protocol       = each.value.ip_protocol
  to_port           = each.value.to_port
}

## Network interface and IP configuration
resource "aws_network_interface" "instance" {
  subnet_id       = var.subnet_id
  security_groups = [ aws_security_group.instance.id ]

  tags            = merge({
                        Name = "${var.name}-nic"
                    }, var.tags)
}
resource "aws_eip" "instance" {
  count             = var.enable_pub_ip ? 1:0
  network_interface = aws_network_interface.instance.id
  domain            = "vpc"
  tags              = merge({
                                Name = "${var.name}-eip"
                            }, var.tags)
}

output "public_ip" {
  value = var.enable_pub_ip ? aws_eip.instance[0].public_ip : null
}
output "private_ip" {
  value = aws_network_interface.instance.private_ip
}

## Instance
locals {
  // if private key is provided, create a script to copy the private key to /home/ubuntu/.ssh/id_rsa
  set_private_key_script = var.private_key == null ? []: [
<<-EOF
#!/bin/bash
set -euxo pipefail

mkdir -p /home/ubuntu/.ssh
echo '${base64encode(var.private_key)}' \
  | base64 -d \
  > /home/ubuntu/.ssh/id_rsa

chown ubuntu:ubuntu /home/ubuntu/.ssh
chown ubuntu:ubuntu /home/ubuntu/.ssh/id_rsa

chmod 700 /home/ubuntu/.ssh
chmod 600 /home/ubuntu/.ssh/id_rsa

EOF
]

  // if additional bootstrap script are provided, include the bootstrap script into the user_data
  bootstrap_scripts = concat(local.set_private_key_script, var.bootstrap_scripts)

  rendered_scripts = join("\n\n", [
    for idx, script in local.bootstrap_scripts : <<-EOT
cat >/tmp/bootstrap-${format("%02d", idx)}.sh <<'SCRIPT_EOF'
${script}
SCRIPT_EOF

chmod +x /tmp/bootstrap-${format("%02d", idx)}.sh
/tmp/bootstrap-${format("%02d", idx)}.sh
EOT
  ])

  user_data = <<-EOF
#!/bin/bash

set -euxo pipefail

${local.rendered_scripts}
EOF

  user_data_hash = sha1(local.user_data)

}

resource "null_resource" "user_data_hash" {
  triggers = {
    user_data_hash = local.user_data_hash
  }
}

resource "aws_instance" "instance" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_name

  user_data     = local.user_data == null ? null : local.user_data

  network_interface {
    network_interface_id = aws_network_interface.instance.id
    device_index         = 0
  }

  credit_specification {
    cpu_credits = "unlimited"
  }
  tags   = merge({
              Name = var.name
            }, var.tags)

  lifecycle {
    ignore_changes = [ ami ]
    replace_triggered_by = [null_resource.user_data_hash]
  }
}