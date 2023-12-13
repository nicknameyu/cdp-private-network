# Change log
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