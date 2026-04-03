
# This is an example of the terraform tfvars file. 
```
owner = "owner"

cdp_bucket_name = "owner-cdp-poc-bucket"

cross_account_role = "owner-cdp-poc"
cmk_key_name = "owner-cdp-poc-key"

default_permission = true
custom_dns = true


cdp_xaccount_external_id = "*** external ID ***"

//create_windows_jumpserver = true
public_snet_to_firewall = false

tags = {
    usecase = "testing"
}


## Permissions
enable_ai = true
enable_cmk = true
enable_de = true
enable_df = true
enable_dw = true
create_eks_role = false

```