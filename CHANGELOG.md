# Change log

## v0.3.8 AWS
- Adding an option to allow using customer cross account role policy. 
- Move routing resources to a new `routing.tf` file to reduce the number of resources in `network.tf `.
- Move DNS resources to a new `dnsresolver.tf` file to reduce the number of resources in `network.tf `.
- Move S3 VPC Gateway endpoint resources to a new `s3endpoint.tf` file to reduce the number of resources in `network.tf `.
- Remove KMS interface endpoint cause it is useless without private hosted zone. Further study may be required how to use interface endpoint in private deployment.
- Added 3 public subnet in core VPC so that this network can allow creating public environment.
- Add `s3:DeleteObjectVersion` permission to ranger role on `s3://<bucket>/data/*`. THis is for RAZ. DL provisioning fails without this permission.
 
## v0.3.7 Azure
- Default RBAC permission control on Key Valt.

## v0.3.6 Azure
- Allow hub VNET to access the file storage.
- Additional permission for liftie base on doc update.

## v0.3.5 AWS
- Add a couple of firewall rules for NIFI operator
- Add a couple s3 bucket policies for ranger audit role to allow ranger audit role:
```
          "s3:ListBucketMultipartUploads",
          "s3:PutObject",
          "s3:DeleteObject"
```
- move kms interface endpoint to network file.

## v0.3.24 Azure
- Adding feature to enable creating private DNS zone in another subscription.
- Adding custom role definition for private DNS zones to be created in another subscription so that it can be used to grant permission to SPN and MI in another subscription to enable them to manupulate the records in the private DNS zones in that subscription.
- Removing custom role `env_single_rg_svc_ep` because it is nolonger required.
- Renaming custom role `env_single_rg_pvt_ep` to `datalake`.

## v0.3.23 Azure
- Add 4 public subnets in hub VNET for the convience of creating full public environment.
- Add new permissions based on testing on Jan 10, 2025.

## v0.3.22 Azure
- For private environment, disable public routing on the subnets in CDP VNET.
- Increase delay interval to 5min for the custom role assignment. 
- Remove storage account endpoints from firewall. They are not required when service endpoint is enabled.
- Fix bug of firewall allowing everything.

## v0.3.21 Azure
- CMK permission update. DF needs `Encrypt` and `Dycrypt` permissions for `data admin` managed identity.
- CMK custom role needs to be assigned to `data admin` managed identity. 

## v0.3.20 AWS
- Fix logic bug for `create_eks_role`
- fix issue introduced by new version of bind9 on dns server.

## v0.3.19 Azure
- Add a variable `public_env` to control the default route on the route tables for CDP VNET.
- Change terraform AzureRM provider version, refactor the deprecated features.
- Introduce variables to control creating windows jump server and CDP jump server per request instead of creating by default
- Change Postgres DB Private DNS zone name to privatelink to accomondate both privatelink and delegated subnet.
- Add MySql private DNS zone for Data Engineering
- Update custom role permission to for above changes.

## v0.3.18 Azure
- VM image update due to Azure end of life.

## v0.3.17 Azure
- Use `azurerm_key_vault_access_policy` to create key vault access policy for SPN and dataaccess MI, instead of embed them in the `azurerm_key_vault` resource. 
- Adjust the bootstrap script for the DNS server, so that the terraform apply will fail out if the DNS service cannot be started successfully.

## v0.3.16 Azure
- create default values for many variables to reduce the required parameters in `tfvars` file
- Create delay for role assignment after custom roles are created to avoid failures. 
- removed two manage identities, `db_cmk` and `dw`, as the `dataaccess` MI can be used for this purpose.

## v0.3.15 aws permission
- adding tagrole permission
## v0.3.14-1
- change default value of `create_eks_role` to false.

## v0.3.14 
- tag policy
## v0.3.13 aws & azure template
### AWS
- Add variable `cdp_xaccount_account_id` and `cdp_xaccount_external_id` so that these two variable can be customized. 
- Fix a bug for reduced permission policy.
- Enable a windows server as the windows jump server in public subnet.
### Azure
- Add firewall rule resource as the dependency for jump server to avoid bootstraping server without firewall rules.

## v0.3.12 aws template
- add variable `create_eks_role` to control whether to create EKS role cloudformation stack under reduced permission scenario.

## v0.3.11-1 a few description bugs
## v0.3.11 aws minimum policy update
- Added minimum permission policy to aws template

## v0.3.10-1 Provide an instruction file for the paramenters of each template
## v0.3.10 Azure template
- Create private dns zone for dfs storage and link hub vnet to the private dns zone
- Create private end point for dfs storage.
- remove space in the key vault access policy permission `Wrap Key` -> `WrapKey`; `Unwrap Key` -> `UnwrapKey`. 
- Keyvault name variable default to "".
- azurerm provider updated to latest version.

## v0.3.9 AWS template and Azure template
### Azure template
- New managed identity for database encryption with CMK.
### AWS template
- Use the Linux jump server as DNS server. Cause this can be automatically configured with terraform user data and provisioniner. 
- Remove the original Windows DNS server.

## v0.3.8 Azure template
- Use hub-jump Linux server as DNS server.
  - Automatically configure the DNS server on the Linux VM.
- Create a Win11 VM as client.
- Remove the Windows Server as DNS server.
## v0.3.7
### AWS template
- Remove variables for subnet CIDR. Calculate the subnets CIDR from VPC CIDR.
- Add ssh private key to linux jump servers.
### Azure template
- Adjusted subnet CIDR for CDP VNET. 
- Add azurerm provider feature to delete everyting when destroy

## v0.3.6 Azure template
- Remove variables for subnet CIDR. Calculate the subnets CIDR from VNET CIDR.
- Add network architecture of this terraform template in readme.
- Add a switch variable `spn_permision_contributor` to control whether to grant contribotor permission to SPN.
- This version is tested with all Data services. 

## v0.3.5 Azure template
- Custom role update to add postgres DB flexible server. This version is good for every service except DE.
- Custom role update to add azure market image permission
- Remove multiple resource group private endpoint custom role as it is deprecated.
- Enable Key Valt perge protection as it is mandatory.
- Add a firewall rule to allow "*.docker.io"

## v0.3.4 AWS template
- Add two security groups, knox and default
## v0.3.3 AWS template
- Add a variable to control key alias.

## v0.3.2 Azure template
- Add a switch to control the custom DNS setting of the VNETs. When true, the DNS setting points to custom DNS server. When true, use Azure Default DNS.
## v0.3.1 Fix issues with Europe and AP regions
- Both AWS and Azure templates have been tested with US/EU/AP regions for Environment/Datalake/Datahub/K8s based data services.
- Optimize variable descriptions and format.
- Fix a few bugs related to EU and AP regions.

## v0.3.0 AWS
- Custom DNS configuration

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