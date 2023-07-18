# tfvars example

```
hub_vnet_name = "dyu-hub-vnet"
cdp_vnet_name = "dyu-cdp-vnet"
firewall_name = "dyu_firewall"
managed_id = {
  assumer    = "dyu-cdp-assumer"
  dataaccess = "dyu-cdp-dataaccess"
  logger     = "dyu-cdp-logger"
  ranger     = "dyu-cdp-ranger"
  raz        = "dyu-cdp-raz"
  dw         = "dyu-cdp-dw"
}

 resource_groups = {
    network_rg      = "dyu-network"
    prerequisite_rg = "dyu-cdp-prerequisite"
    cdp_rg          = "dyu-cdp-env"
    vms_rg          = "dyu-vms"
  }

dns_server_name      = "dyu-dns"
cdp_jump_server_name = "dyu-cdp-jump"
hub_jump_server_name = "dyu-hub-jump"

tags = {
      owner = "dyu@cloudera.com"
      usecase = "testing"
    }

cdp_storage = "dyucdpstorage"

admin_username = "dyu"
custom_role_names = {
  dw                   = "DYU CDP for CDW"
  liftie               = "DYU CDP for Liftie"
  env_single_rg_svc_ep = "DYU CDP Single RG SvcEndpoint"
  env_single_rg_pvt_ep = "DYU CDP Single RG PvtEndpoint"
  env_multi_rg_pvt_ep  = "DYU CDP Multiple RG PvtEndpoint"
  cmk                  = "DYU CDP CMK"
}
```