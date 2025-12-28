
module "hub_vnet" {
  source                = "./modules/az-vnet"
  location              = var.location
  create_resource_group = true
  resource_group_name   = var.resource_groups != null ? var.resource_groups.network_rg : "${var.owner}-network"
  vnet_name             = var.hub_vnet_name == null ? "${var.owner}-hub-vnet" : var.hub_vnet_name
  cidr                  = var.hub_cidr
  std_subnets = {
    pub_subnet_1        = cidrsubnet(var.hub_cidr, 8, 1 )
    pub_subnet_2        = cidrsubnet(var.hub_cidr, 8, 2 )
    pub_subnet_3        = cidrsubnet(var.hub_cidr, 8, 3 )
    pub_subnet_4        = cidrsubnet(var.hub_cidr, 8, 4 )
    pub_subnet_5        = cidrsubnet(var.hub_cidr, 8, 5 )
    pub_subnet_6        = cidrsubnet(var.hub_cidr, 8, 6 )
    pub_subnet_7        = cidrsubnet(var.hub_cidr, 8, 7 )
    pub_subnet_8        = cidrsubnet(var.hub_cidr, 8, 8 )
  }
  nva_subnets = {
   AzureFirewallSubnet  =  cidrsubnet(var.hub_cidr, 10, 0 )
  }
  tags                  = var.tags
}

module "spoke_vnet" {
  source                = "./modules/az-vnet"
  resource_group_name   = module.hub_vnet.resource_group_name
  vnet_name             = var.cdp_vnet_name == null ? "${var.owner}-cdp-vnet" : var.cdp_vnet_name
  cidr                  = var.cdp_cidr
  location              = var.location
  std_subnets = {
    pvt_subnet_1        = cidrsubnet(var.cdp_cidr, 8, 1 )
    pvt_subnet_2        = cidrsubnet(var.cdp_cidr, 8, 2 )
    pvt_subnet_3        = cidrsubnet(var.cdp_cidr, 8, 3 )
    pvt_subnet_4        = cidrsubnet(var.cdp_cidr, 8, 4 )
    pvt_subnet_5        = cidrsubnet(var.cdp_cidr, 8, 5 )
    pvt_subnet_6        = cidrsubnet(var.cdp_cidr, 8, 6 )
    pvt_subnet_7        = cidrsubnet(var.cdp_cidr, 8, 7 )
    pvt_subnet_8        = cidrsubnet(var.cdp_cidr, 8, 8 )
  }
  delegate_subnets = {
    pg_flex   = {
      prefix  = cidrsubnet(var.cdp_cidr, 12, 0)
      service = "Microsoft.DBforPostgreSQL/flexibleServers"
    }
  }
  tags                 = var.tags
}

####### Peering #####
resource "azurerm_virtual_network_peering" "hub_spoke" {
  name                      = "hub_spoke"
  resource_group_name       = module.hub_vnet.resource_group_name
  virtual_network_name      = var.hub_vnet_name == null ? "${var.owner}-hub-vnet" : var.hub_vnet_name
  remote_virtual_network_id = module.spoke_vnet.vnet_id
}

resource "azurerm_virtual_network_peering" "spoke_hub" {
  name                      = "spoke_hub"
  resource_group_name       = module.spoke_vnet.resource_group_name
  virtual_network_name      = var.cdp_vnet_name == null ? "${var.owner}-cdp-vnet" : var.cdp_vnet_name
  remote_virtual_network_id = module.hub_vnet.vnet_id
}
