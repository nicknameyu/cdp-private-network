# Terraform AWS Infrastructure Configuration

## Overview

This repository contains Terraform configurations for setting up an AWS infrastructure tailored for Cloudera's CDP environment. The configuration includes VPCs, subnets, internet gateways, NAT gateways, transit gateways, and firewall rules, among other resources.

## Variables

### General Configuration

- **`owner`** (string): Owner name. Will be used as a prefix for many resources created by this template.
- **`region`** (string): AWS region to deploy resources in. Default is `us-west-2`.

### S3 Buckets

- **`cdp_bucket_name`** (string): Name of the S3 bucket for CDP. Default is `null`. If `null` a default name will be applied with the prefix of `${owner}-`.

### VPC Configuration

#### Core VPC

- **`core_vpc`** (object): Configuration for the core VPC.
  - **`name`** (string): Name of the core VPC.
  - **`cidr`** (string): CIDR block for the core VPC. Must be at least a /26 subnet.
  - **Validation**: Ensures a minimum /26 CIDR block is used.

#### CDP VPC

- **`cdp_vpc`** (object): Configuration for the CDP VPC.
  - **`name`** (string): Name of the CDP VPC.
  - **`cidr`** (string): CIDR block for the CDP VPC. Must be at least a /22 subnet.
  - **Validation**: Ensures a minimum /22 CIDR block is used.

### Gateway and Firewall

- **`tgw_name`** (string): Name of the transit gateway.
- **`fw_name`** (string): Name of the firewall.
- **`igw_name`** (string): Name of the internet gateway.
- **`natgw_name`** (string): Name of the NAT gateway.

### SSH Configuration

- **`ssh_key`** (object): SSH key configuration.
  - **`public_key_path`** (string): Path to the SSH public key. Default is `~/.ssh/id_rsa.pub`.
  - **`private_rsa_key_path`** (string): Path to the RSA private key. Default is `~/.ssh/id_rsa`.

### Cross Account Role

- **`cross_account_role`** (string): Switch to control the creation of a cross account role. If `null`, the role will be created. If set, the role will be imported. Default is `null`.

### Firewall Domains and Endpoints

- **`fw_domain_ep`** (list): List of domain endpoints for firewall rules. Includes Cloudera, AWS services, Docker, and other necessary endpoints. The default value is based on the document on Cloduera website.
- **`fw_http_ep`** (list): List of HTTP endpoints for firewall rules. Default includes Ubuntu update servers.

### AWS SSO

- **`aws_sso_user_arn_keyword`** (string): Keyword for creating trust relationships for cross account roles. Default is `cldr_poweruser`.

### Firewall Control

- **`firewall_control`** (bool): Controls whether CDP VPC internet traffic is controlled by the firewall. Default is `true`.
- **`public_snet_to_firewall`** (bool): Controls whether public subnet internet traffic is controlled by the firewall. Default is `true`.

### Custom DNS

- **`custom_dns`** (bool): Controls whether custom DNS is used in CDP VPC. Default is `true`.

### KMS Key

- **`cmk_key_name`** (string): Alias for the KMS key to be created. If `null`, a key with the alias `<owner>-cdp-key` is created. Default is `null`.

### Permission
- **`default_permission`** (bool): switch for whether default permission should be used for cross account role. Default to true. If set to false, the tempalted will created a role pair for Liftie EKS cluster and assign reduced policies to the cross account role.

- **`create_eks_role`** (bool): This is a switch to control whether to create Cloudformation stack for EKS role/instance profile under reduced permission.
  - When using default permission, this variable is ignored.
  - When using reduced permission, this variable default to true. 
    - When conflicting with an existing role, that means the cloudformation stack has been created in this AWS account, please set this variable to false to avoid the conflict.

## Usage

To use this Terraform configuration, ensure you have Terraform installed and configured with AWS credentials. Clone the repository, customize the variables as needed, and run the following commands:

```sh
terraform init
terraform plan
terraform apply
```