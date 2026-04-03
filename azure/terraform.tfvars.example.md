# tfvars example

```
tags = {
  owner = "owner"
  usecase = "testing"
}

location = "eastus2"
subscription_id = "XXXXXXXXXXXXX"                //Subscription ID that CDP will be deployed
dns_zone_subscription_id = "XXXXXXXXX"           //Subscription ID that the private DNS zones will be created.
tenant_id = "XXXXXXXX"
cdp_storage = "<storage account name>"
cdp_file_storage = "<storage account name>"

spn_object_id = "XXXXXXXXX"  //this need to be the object id of the Enterprise application instead of the application registration
kv_name = "<key vault name>"


//create_win_client = true
create_cdp_jump_server = true

owner = "owner"
//spn_permision_contributor = true

// public_env = true



kv_rbac=true

```