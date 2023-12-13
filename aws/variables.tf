variable "owner" {
  type = string
}
variable "region" {
  type = string
  default = "us-west-1"
}
variable "available_az" {
  type = list(string)
  default = ["us-west-1b", "us-west-1c"]
}
variable "core_vpc" {

}
variable "cdp_vpc"{

}
variable "tgw_name" {
  type = string
}
variable "fw_name" {
  type = string
}
variable "core_subnets" {
  default = {
    core = {
        name = "coresubnet"
        cidr = "10.1.0.0/28"
    }
    nat = {
        name = "natsubnet"
        cidr = "10.1.0.16/28"
    }
    firewall = {
        name = "firewallsubnet"
        cidr = "10.1.0.32/28"
    }
    private = {
        name = "privatesubnet"
        cidr = "10.1.0.48/28"
    }
  }
}

variable "cdp_subnets" {

  default = {
    subnet1 = {
        name = "subnet1"
        cidr = "10.2.0.0/24"
        az   = "us-west-1b"
    }
    subnet2 = {
        name = "subnet2"
        cidr = "10.2.1.0/24"
        az   = "us-west-1c"
    }
  }
}

variable "ssh_key" {
  type = string
  default = ""
}

variable "igw_name" {
  type = string
}
variable "natgw_name" {
  type = string
}

variable "aws_dns" {
  type = bool
  description = "A switch to control whether enabling AWS provided DNS for the VPC. Default to true. Need to be false if using custom private DNS."
  default = true
}

variable "create_cross_account_role" {
  type = bool
  description = "A switch to control whether to create cross account role. Default to true. "
  default = true
}