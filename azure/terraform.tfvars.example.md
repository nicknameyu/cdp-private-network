# tfvars example

```
hub_vnet_name = "dyu-hub-vnet"
cdp_vnet_name = "dyu-cdp-vnet"
firewall_name = "dyu_firewall"
dns_resolver_name = "dyu_cdp_dns_resolver"
managed_id = {
  assumer    = "dyu-cdp-assumer"
  dataaccess = "dyu-cdp-dataaccess"
  logger     = "dyu-cdp-logger"
  ranger     = "dyu-cdp-ranger"
  raz        = "dyu-cdp-raz"
  dw         = "dyu-cdp-dw"
  dbcmk      = "dyu-cdp-db-cmk"
}

 resource_groups = {
    network_rg      = "dyu-network"
    prerequisite_rg = "dyu-cdp-prerequisite"
    cdp_rg          = "dyu-cdp-env"
    vms_rg          = "dyu-vms"
  }

winclient_vm_name      = "dyu-win11"
cdp_jump_server_name = "dyu-cdp-jump"
hub_jump_server_name = "dyu-hub-jump"

tags = {
      owner = "dyu@cloudera.com"
      usecase = "testing"
    }

// Please make sure the names for storage account do not exceed 24 charactors. 
cdp_storage = "dyucdpstorage"
cdp_file_storage = "dyucdpfilestorage"

admin_username = "dyu"
custom_role_names = {
  dw                   = "DYU CDP for CDW"
  liftie               = "DYU CDP for Liftie"
  env_single_rg_svc_ep = "DYU CDP Single RG SvcEndpoint"
  env_single_rg_pvt_ep = "DYU CDP Single RG PvtEndpoint"
  cmk                  = "DYU CDP CMK"
  mkt_img              = "DYU Market Image"
}

// An Application registration is required before setting this.
spn_object_id = "******"  //this need to be the object id of the Enterprise application instead of the application registration
kv_name = "dyucdpkeyvault"
```