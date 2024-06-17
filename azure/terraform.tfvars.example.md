# tfvars example

```
tags = {
  owner = "dyu"
  usecase = "testing"
}

cdp_storage = "dyucdpstorage"
cdp_file_storage = "dyucdpfilestorage"

spn_object_id = "f6775847-daeb-4574-bab5-93775a901321"  //this need to be the object id of the Enterprise application instead of the application registration
kv_name = "dyupoccdpkv"


password = "Passw0rd"

owner = "dyu"
// An Application registration is required before setting this.
spn_object_id = "******"  //this need to be the object id of the Enterprise application instead of the application registration

```