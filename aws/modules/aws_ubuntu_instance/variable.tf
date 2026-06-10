## AMI info
variable "ami_filter" {
  type = string
  default = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"
  description = "Filter string for AMI"
}
variable "ami_owner" {
  type = string
  default = "099720109477"      # Canonical
  description = "AMI owner"
}

## Tags
variable "name" {
  type = string
  description = "Name tag for the instance"
}

variable "tags" {
  type = map(string)
  default = {}
  description = "Tags for the resources"
}

## Network
variable "vpc_id" {
  type = string
  description = "VPC ID"
}
variable "subnet_id" {
  type = string
  description = "Subnet ID"
}

variable "sg_ingress_rules" {
  type = map(object({
    from_port        = number
    to_port          = number
    ip_protocol      = string
    cidr_block       = string
  }))
  default = {}
  description = "Map of the ingress rules for the security group. The key will be the description of the rule definition."
}
variable "sg_egress_rules" {
  type = map(object({
    from_port        = number
    to_port          = number
    ip_protocol      = string
    cidr_block       = string
  }))
  default = {}
  description = "Map of the egress rules for the security group. The key will be the description of the rule definition."
}

variable "enable_pub_ip" {
  type = bool
  default = false
  description = "Flag for whether to enable public IP."
}

## Instance
variable "instance_type" {
  type = string
  default = "t2.micro"
  description = "Instance Type"
}
variable "key_name" {
  type = string
  description = "Name of the SSH Key pair for this instance."
}

## bootstrap scripts
variable "bootstrap_scripts" {
  type = list(string)
  default = []
  description = "List of paths to the bootstrap scripts."
}
variable "private_key" {
  type = string
  default = null
  description = "SSH private key to be stored in file ~/.ssh/id_rsa. "
}
