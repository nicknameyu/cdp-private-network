### Universal variables
variable "tags" {
  description = "Tags to be applied to the resources."
  type = map(string)
  default = null
}

variable "location" {
  description = "Azure region where the resources will be created."
  type = string
  default = "westus2"
}

##### Resouce group 
variable "resource_group_name" {
  type = string
  description = "Name of the resource group to hold the DNS server. "
}
variable "create_resource_group" {
  type = bool
  default = false
  description = "A switch to control whether to create resource group for DNS server."
}

##### Virtual Machine

variable "vm_name" {
  type = string
  description = "The name of the virtual machine."
}
variable "create_public_ip" {
  type = bool
  default = false
  description = "A flag to control whether to create public IP for this server."
}
variable "vm_subnet_id" {
  type = string
  description = "Azure resource ID of the subnet to create this VM."
}
variable "use_nsg" {
  type = bool
  default = false
  description = "A flag to set whether to use Network Security Group. Default to false."
}
variable "ssh_pub_key" {
  type = string
  default = "~/.ssh/id_rsa.pub"
  description = "Path to the ssh public key. Public key will be configured to \"~/.ssh/authorized_keys\"."
}
variable "ssh_private_key" {
  type = string
  default = "~/.ssh/id_rsa"
  description = "Path to the ssh private key. Private key will be configured to \"~/.ssh/id_rsa\". "
}
variable "admin_username" {
  type = string
  default = "ubuntu"
  description = "The user name to login the dns server. "
}
variable "vm_size" {
  type = string
  default = "Standard_DS1_v2"
}
##### Bootstrapping 

variable "user_data" {
  type = string
  default = null
  description = "Content of the user_data to bootstrap the server."
}
