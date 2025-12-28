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

variable "create_resource_group" {
  type        = bool
  default     = false
  description = "A switch to control whether to create resource group. Default to false."
}
variable "resource_group_name" {
  type        = string
  description = "Name of the resource group to hold the resources."
}
variable "firewall_name" {
  type        = string
  description = "Name of the firewall to be created."
}
variable "firewall_subnet_id" {
  type        = string
  description = "Azure resource ID of the firewall subnet."
}
variable "egress_source_cidrs" {
  type        = list(string)
  description = "List of CIDRs of private network to be allowed for outbound requrests. "
}

variable "subnets" {
  type        = map(string)
  description = "Map of subnets that need this Firewall to be their egress control."
}