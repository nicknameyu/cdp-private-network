# CDP Public Cloud Private Network

The template in this repo is `NOT` to create CDP installation. It's to create a hub-spoke network, custom private DNS, Firewall, as well as jump servers to mimic the `MOST TYPICAL` customer network setup. So that internal engineers can reproduce the problems they run into or test some assumptions easier.


## Usage
- Populate `terraform.tfvars` file and run terraform command to deploy the resources
### AWS
- The network environment contains
  - Core VPC to hold the jump server, DNS server, Firewall, NAT gateway
    - core subnet
    - NAT gateway subnet
    - Firewall subbet
    - private subnet
    - A linux Jump server with public IP
    - A windows DNS server with Public IP. The DNS server needs manual configuration.
  - CDP VPC for the CDP deployment
    - 3 subnets each in different AZ
    - A Linux jump server
    - Private DNS resolver
    - DHCP option set is created with a variable to control wither to use AWS default DNS or custom private DNS.
      - CDW doesn't support custom private DNS. Please leave variable `custom_dns` to `false` when deploying DW
      - DE/DF/ML support custom private DNS. When testing custom private DNS, user can set `custom_dns` to `true`.
        - Please also configure the DNS server in the core VPC to conditional forward `efs.<region>.amazonaws.com` to the DNS private resolver inbound IP addresses.
    - S3 VPC Gateway endpoint and related route rules
  - AWS transit gateway to connect the CDP VPC with the core VPC
  - CDP prerequisite resources
    - S3 bucket
    - Cross account role
    - IAM policies, roles, instance profiles

### Azure
- The network environment contains
- HUB VNET to hold the jump server, DNS server, Firewall.
  - Firewall subnet
  - core subnet
    - DNS server
    - jump server
- CDP VNET
  - a few subnets with different CIDR range for testing
  - a Linux jump server
- Configure to use the DNS server public IP to rdp into the DNS server
  - Create DNS services
  - Create conditional forward to `dns_resolver_inbound_ip` for privatelink domains.
    - `privatelink.mysql.database.azure.com`
    - `privatelink.<region>.azmk8s.io`
    - `<region>.postgres.database.azure.com`: if postgres flexible servier is used.
    - `privatelink.blob.core.windows.net`: if service endpoint is not allowed
    - `privatelink.file.core.windows.net`: if service endpoint is not allowed
    - `privatelink.postgres.database.azure.com`: if service endpoint is not allowed
