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

### VNET Variables

variable "create_resource_group" {
  type        = bool
  default     = false
  description = "A switch to control whether to create resource group. Default to false."
}
variable "resource_group_name" {
  type        = string
  description = "Name of the resource group to hold the resources."
}
variable "vnet_name" {
  type        = string
  description = "Name of the VNET to be created."
}

variable "cidr" {
  type        = string
  description = "CIDR for the VNET."
}

#### subnets
variable "std_subnets" {
  type        = map(string)
  description = "Standard subnets. `key` is the name of the subnet, `value` is the CIDR for the subnet. Route table will be created accordingly with naming standard of `rt_<subnet name>`."
  default     = {}
}
variable "delegate_subnets" {
  type        = map(object({
    prefix    = string
    service   = string
  }))
  default     = {}
  description = "Delegated subnets. Used for creating delegated subnets. `Key` is the name of the subnet, `prefix` is the IP address space, `service` is the service to delegate."
}
variable "nva_subnets" {
  type        = map(string)
  default     = {}
  description = "Appliance subnets. `key` is the name of the subnet, `value` is the CIDR for the subnet."
}
