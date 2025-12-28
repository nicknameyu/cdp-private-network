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
####### Private DNS zones ######
variable "subscription_id" {
  ## Many customer has a centralized hub subscription for private dns zones.
  type = string
  default = ""
  description = "The subscription ID of the private DNS zones to be created. Default to use current subscription. " 
}
variable "resource_group_name" {
  type = string
  description = "The resoruce group name for private DNS zones."
}
variable "create_resource_group" {
  type = bool
  default = true
  description = "A bool switch to control whether to create private dns zone resource group."
}
variable "private_dns_zones" {
  type = map(string)
  default = null
  description = "The map between key and the private DNS zone name. Default to null. When set to null, 4 private DNS zones will be created for AKS, Postgres DB, MySQL, and DFS."
}
locals {
  private_dns_zones = var.private_dns_zones == null ? {
    aks     = "privatelink.${var.location}.azmk8s.io"
    pgdb    = "privatelink.postgres.database.azure.com"
    mysql   = "privatelink.mysql.database.azure.com"
    storage = "privatelink.dfs.core.windows.net"
  } : var.private_dns_zones
}
variable "vnet_ids" {
  type = map(string)
  default = {}
  description = "Map between a key and the IDs for the VNETs to be linked to the private DNS zones. Eg. {hub = <hub VNET ID>; spoke = <spoke VNET ID> }"
}