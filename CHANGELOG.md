# Change log

## v0.2.9 AWS
- finalize firewall rules for data service

## v0.2.8 Azure and AWS
- Azure: Add service endpoint to PostgreSQL Flexible server delegated network to avoid removing it when re-apply the template.
- AWS:
  - Add `firewall_control` variable to switch beteen firewall control and no firewall control. This is for testing purpose.
    - code for route tables are changed accordingly.
  - Add `lifecycle` to dns server ami.
  - Firewall rules update for data services.
  - Now this version can successfully facilitate all data services.

## v0.2.7 Azure
- Add delegated subnet for Azure Postgres DB Flexible server. 
- Change Azure storage location output format.

## v0.2.6 AWS
- Add a trust relationship policy statement to cross account role so that a user can be trusted to assume the cross account role for administration tasks. This is usually for the EKS clusters. 

## v0.2.5 Azure and AWS
- Bug fix:
  - added `s3.us-west-2.amazonaws.com` to firewall rule. This is not on our document. But DF fails downloading flow without it. 
- 3rd subnet for AWS cdp VPC.

## v0.2.4 Auzre
- Bug fix: 
  - disable key vault purge protection, so that it can be recreated. 
  - purge key vault when destroy
  - If the key vault is deleted outside terraform, it may not have been purged. In this case, the key vault will be recovered, but key will run into error cause the recovered key is outstanding. In this case, there are several ways to remediate the failure.
    - Option 1: manually import the key.
    - Option 2: After running into error, comment off the key vault name, and run `terraform apply` so that terraform will purge the key vault; then uncomment the kv name, and run `terraform apply`.
    - Option 3: manually purge the key vault and run `terraform apply`.

## v0.2.3 AWS
- KMS VPC endpoint
- Firewall rule group to allow Ubuntu repository and AWS cli
- Upcomine features
  - RAZ support
  - Custom Private DNS server

## v0.2.2 AWS
- Egress controlled by firewall
  - route table adjusted
  - Firewall rules added
- DNS server added
  - a windows server. Need manually configure the DNS service
  - This is also a windows jump server, which will allow user to log on the CDP services. 
- Upcomine features
  - KMS VPC endpoint
  - RAZ support
  - Custom Private DNS server

## v0.2.1 AWS
- adding lifecycle to instance resources so that instance won't need to be replaced when the ami data resource come back with a different ami id.
- KMS key for encription.
  - Key/KeyAlias
  - Permisions required for KMS encryption.
- Upcomine features
  - KMS VPC endpoint
  - Egress controlled by firewall
  - RAZ support
  - Custom Private DNS server

## v0.2.0 Add AWS template
- This is the first AWS template. 
- There is a hub-spoke network architecture in this template, core VPC, CDP VPC and transit gateway.
- Egress from core VPC.
- CDP prerequisite resources are created in this template. Plus cross account role and public key.
- Future features:
  - Egress controlled by AWS network firewall
  - Custom private DNS server.
  - RAZ support.
  - KMS support.

## v0.1.5 azure core subnet route egress from firewall
- Add route table to core subnet in hub vnet to control core subnet egress from firewall.
  - Add firewall rule to allow egress from core subnet
- ignore access policy changes in KeyVault

## v0.1.5 more azure fw rules
- Add a few firewall rules for microsft tools. They are required to install Azure CLI 

## v0.1.4 azure template
- remove resolver subnet from hub vnet
- add lifecycle configuration to route table resource to avoid deletion of routes for AKS
- remove CCMv1 related firewall rule

## v0.1.3 Azure template
- Add Azure file share for ML workspace

## v0.1.2 Azure template
- Add some firewall rules for AKS
- Add CMK related resources
- Add pre-created NSG
- Assign custom roles to SPN

## v0.1.1 Azure template
- Add Azure Private DNS resolver
- Add some output for ip addresses to be used in lab testing.
- Add dependency for role assignment resources

## v0.1.0: Azure template