
# This is an example of the terraform tfvars file. 
```
owner = "dyu"

core_vpc = {
    name = "dyu_core_vpc"
    cidr = "10.1.0.0/16"
}
cdp_vpc = {
    name = "dyu_cdp_vpc"
    cidr = "10.2.0.0/16"
}

igw_name = "dyu_igw"
natgw_name = "dyu_natgw"
tgw_name = "dyu_tgw"
fw_name = "dyu-fw"

```