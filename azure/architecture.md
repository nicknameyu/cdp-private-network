# Architecture Design

## CDP Pre-requisite resource group
- ADLS Storage account 
  - data container
  - log container
  - backup container
- File storage for ML workspace
- Key vault for CMK encryption
- Managed identities
  - Assumer identity
  - data access identity
  - log identity
  - Ranger identity
  - RAZ identity
  - DW identity
- Permission

## Network resource group
- dyu-hub-vnet
  - CIDR: 10.128.0.0/16
  - subnets
    - firewall subnet
    - core subnet
- dyu-cdp-vnet
  - CIDR: 10.100.0.0/16, 10.200.0.0/16
  - Subnets
    - 26subnet1: 10.100.0.0/26
    - 26subnet2: 10.100.0.64/26
    - 25subnet1: 10.100.0.128/25
    - 24subnet1: 10.100.1.0/24
    - 23subnet1: 10.100.2.0/23
    - 22subnet1: 10.100.4.0/22
    - 21subnet1: 10.100.8.0/21
    - resolver
  - Route tables: for each of the subnets in the vnet, internet egress routing to firewall ip address
  - AKS private DNS zone
  - network security groups

## Servers
- DNS server
  - deployed in core subnet of hub VNET
  - Windows 2019 server
- Jump servers
  - jump server in hub vnet: ubuntu2004 LTS
  - jump server in cdop vnet: ubuntu 2004 LTS

## firewall
- Azure firewall
- Public IP
  - Firewall ip
  - jump server ip
  - DNS server ip
- Firewall application policy
- Firewall network policy
- Firewall DNAT policy for DNS server and jump server
