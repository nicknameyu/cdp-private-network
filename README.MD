# CDP Public Cloud Private Network

This repo is to host terraform templates to create a lab networt environment for CDP public cloud deployment in a full private cloud network environment.

## Usage
- Populate `terraform.tfvars` file and run terraform command to deploy the resources
- Configure use the DNS server public IP ro rdp into the DNS server
  - Create DNS services
  - Create conditional forward with `dns_resolver_inbound_ip` for privatelink domains.