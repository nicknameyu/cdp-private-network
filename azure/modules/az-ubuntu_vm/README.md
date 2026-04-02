# az-ubuntu_vm

A Terraform module that deploys an Ubuntu 22.04 LTS Virtual Machine on Azure. It optionally manages its own resource group, public IP, and Network Security Group, making it suitable for use as a jump host, proxy, or utility VM within a CDP (Cloudera Data Platform) private network.

---

## Usage

```hcl
module "ubuntu_vm" {
  source = "./modules/az-ubuntu_vm"

  resource_group_name = "my-cdp-rg"
  location            = "westus2"
  vm_name             = "cdp-jump-vm"
  vm_subnet_id        = azurerm_subnet.example.id

  create_public_ip = true
  use_nsg          = true

  ssh_pub_key     = "~/.ssh/id_rsa.pub"
  ssh_private_key = "~/.ssh/id_rsa"
  admin_username  = "ubuntu"

  user_data = file("scripts/bootstrap.sh")

  tags = {
    environment = "dev"
    project     = "cdp-private-network"
  }
}
```

---

## Requirements

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.3.0 |
| azurerm   | >= 3.0.0 |

---

## Providers

| Name    | Version  |
|---------|----------|
| azurerm | >= 3.0.0 |

---

## Resources

| Resource                                                  | Description                                                           |
|-----------------------------------------------------------|-----------------------------------------------------------------------|
| `azurerm_resource_group.vm`                               | Created when `create_resource_group = true`                           |
| `data.azurerm_resource_group.vm`                          | Referenced when `create_resource_group = false` (default)             |
| `azurerm_public_ip.vm`                                    | Static public IP, created when `create_public_ip = true`              |
| `azurerm_network_security_group.vm`                       | NSG with allow-all inbound TCP rule, created when `use_nsg = true`    |
| `azurerm_network_interface.vm`                            | NIC attached to the specified subnet                                  |
| `azurerm_network_interface_security_group_association.vm` | Associates the NSG with the NIC when `use_nsg = true`                 |
| `azurerm_linux_virtual_machine.vm`                        | Ubuntu 22.04 LTS VM with SSH key auth and StandardSSD_LRS OS disk     |

---

## Input Variables

| Name                    | Type          | Default               | Required | Description                                                                          |
|-------------------------|---------------|-----------------------|----------|--------------------------------------------------------------------------------------|
| `resource_group_name`   | `string`      | —                     | yes      | Name of the resource group to deploy into                                            |
| `create_resource_group` | `bool`        | `false`               | no       | When `true`, creates the resource group. When `false`, looks it up as a data source  |
| `location`              | `string`      | `"westus2"`           | no       | Azure region where resources will be created                                         |
| `vm_name`               | `string`      | —                     | yes      | Name of the VM (also used to name the NIC, NSG, and public IP)                       |
| `vm_subnet_id`          | `string`      | —                     | yes      | Azure resource ID of the subnet to attach the VM's NIC to                            |
| `vm_size`               | `string`      | `"Standard_DS1_v2"`   | no       | Azure VM SKU / size                                                                  |
| `create_public_ip`      | `bool`        | `false`               | no       | When `true`, creates and attaches a static public IP to the NIC                      |
| `use_nsg`               | `bool`        | `false`               | no       | When `true`, creates an NSG (allow-all inbound TCP) and associates it with the NIC   |
| `admin_username`        | `string`      | `"ubuntu"`            | no       | Admin username for SSH login                                                         |
| `ssh_pub_key`           | `string`      | `"~/.ssh/id_rsa.pub"` | no       | Path to the SSH public key file to install on the VM                                 |
| `ssh_private_key`       | `string`      | `"~/.ssh/id_rsa"`     | no       | Path to the SSH private key (used for provisioning references if needed)             |
| `user_data`             | `string`      | `null`                | no       | Bootstrap script content in plain text; the module base64-encodes it automatically   |
| `tags`                  | `map(string)` | `null`                | no       | Tags applied to all resources                                                        |

---

## Outputs

| Name         | Description                                                        |
|--------------|--------------------------------------------------------------------|
| `public_ip`  | Public IP address of the VM. `null` if `create_public_ip = false` |
| `private_ip` | Private IP address assigned to the VM's NIC                       |

---

## Notes

- **OS image.** The VM is always deployed with Ubuntu 22.04 LTS (`Canonical / 0001-com-ubuntu-server-jammy / 22_04-lts / latest`). The image is not configurable via a variable.
- **SSH only.** Password authentication is disabled. The public key at `ssh_pub_key` is installed for `admin_username`.
- **NSG is permissive.** When `use_nsg = true`, the created NSG allows all inbound TCP traffic. Tighten this rule for production use.
- **user_data encoding.** Pass plain-text script content to `user_data`. The module calls `base64encode()` internally — do not pre-encode the value.
- **Resource group behaviour.** By default (`create_resource_group = false`) the module expects the resource group to already exist. Set `create_resource_group = true` to have the module create it.

---

## Example: Private Jump Host (no public IP)

```hcl
module "jump_vm" {
  source = "./modules/az-ubuntu_vm"

  resource_group_name = azurerm_resource_group.cdp.name
  location            = azurerm_resource_group.cdp.location
  vm_name             = "cdp-jumphost"
  vm_subnet_id        = azurerm_subnet.management.id

  ssh_pub_key = "~/.ssh/id_rsa.pub"

  tags = {
    role = "jumphost"
  }
}

output "jumphost_private_ip" {
  value = module.jump_vm.private_ip
}
```