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

###### HUB VNET configuration #######
variable "hub_vnet_default_dns" {
  type = bool
  default = true
  description = "A bool switch to control the hub VNET Default DNS setting. Default to true, which means to use Azure Default DNS for hub VNET."
}

###### SPOKE VNET configuration #######
variable "spoke_vnet_id" {
  type        = string
  description = "VNET ID of the spoke VNET."
}
variable "spoke_vnet_default_dns" {
  type = bool
  default = false
  description = "A bool switch to control the spoke VNET Default DNS setting. Default to false, which means to use customize DNS for spoke VNET."
}

variable "dns_resolver_subnet_prefix" {
  type = string
  description = "Prefix of the dns resolver inbound subnet. The subnet name is hardcoded to `dns_resolver_inbound`. "
}
variable "private_dns_resolver_name" {
  type = string
  default = ""
  description = "The name of the dns resolver for spoke VNET."
}



####### DNS server configuration ######
variable "dns_server_resource_group_name" {
  type = string
  description = "Name of the resource group to hold the DNS server. "
}
variable "create_dns_server_resource_group" {
  type = bool
  default = false
  description = "A switch to control whether to create resource group for DNS server."
}

variable "dns_server_name" {
  type = string
  default = "dns_server"
  description = "A Linux server with BIND9 configured to provide DNS services."
}
variable "dns_server_subnet_id" {
  type = string
  description = "ID of the subnet to create DNS server."
}
variable "ssh_pub_key" {
  type = string
  default = "~/.ssh/id_rsa.pub"
  description = "Path to the ssh public key. Public key will be configured to \"~/.ssh/authorized_keys\"."
}
variable "ssh_private_key" {
  type = string
  default = "~/.ssh/id_rsa"
  description = "Path to the ssh private key. Private key will be configured to \"~/.ssh/id_rsa\". Assign it to \"\" to disable private key."
}
variable "admin_username" {
  type = string
  default = "ubuntu"
  description = "The user name to login the dns server. "
}
variable "bootstrap_script" {
  type = string
  default = ""
  description = "Path to the bootstrap script. Default to no bootstrapping."
}
variable "conditional_forward_zones" {
  type = object({
    aks   = string
    pgdb  = string
    mysql = string
  })
  description = "Private DNS zones for DNS conditional forward configurations. "
}