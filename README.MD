# CDP Public Cloud Private Network

This repo is to host terraform templates to create a lab networt environment for CDP public cloud deployment in a full private cloud network environment.

## Usage
- Populate `terraform.tfvars` file and run terraform command to deploy the resources
### AWS
### Azure
- Configure to use the DNS server public IP to rdp into the DNS server
  - Create DNS services
  - Create conditional forward to `dns_resolver_inbound_ip` for privatelink domains.
    - `privatelink.mysql.database.azure.com`
    - `privatelink.<region>.azmk8s.io`
    - `<region>.postgres.database.azure.com`: if postgres flexible servier is used.
    - `privatelink.blob.core.windows.net`: if service endpoint is not allowed
    - `privatelink.file.core.windows.net`: if service endpoint is not allowed
    - `privatelink.postgres.database.azure.com`: if service endpoint is not allowed
