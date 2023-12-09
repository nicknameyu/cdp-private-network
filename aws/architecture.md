# Architecture Design

## CDP Pre-requisite resources
- Standard resources: deployed by cloudformation template
- KMS
  - generate a key in the KMS

## Network resources
- Transit gateway: to hold the hub for CDP VNET and core network VNET
- CDP VPC: this is to hold all CDP resources
  - Two private subnets each in different AZ.
- Core VPC: this is to mimic that a DNS server is on another VPC.
  - IGW: for DNS server to reach internet
  - core subnet to hold jump server and dns server. this is a public subnet.
  - Firewall subnet to hold the firewall.
  - NAT subnet to hold the NAT GW.
  - A private subnet which is the landing zone for the traffic routed from CDP VPC.



## Servers
- DNS server
  - deploy in public subnet of DNS VPC
  - Windows 2022 server: password: 
- Jump servers
  - jump server in public subnet of CDP VPC: ubuntu
  - jump server in private subnet of CDP VPC: ubuntu

## firewall
- AWS firewall attach to CDP VPC
  - Firewall policy
    - Firewall rule group
      - allow jump server inbound

