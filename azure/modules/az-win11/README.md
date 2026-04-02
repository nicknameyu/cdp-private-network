# az-win11

Terraform module for deploying a **Windows 11 Pro virtual machine** on Azure. Intended for use as a jump box or desktop client within private network environments (e.g. CDP private network deployments).

The module handles the full VM stack: optional resource group creation, a network interface, an optional static public IP, and an optional Network Security Group — all wired together and ready to use.

---

## Usage

```hcl
module "win11_jumpbox" {
  source = "./modules/az-win11"

  vm_name             = "my-win11-vm"
  resource_group_name = "my-resource-group"
  vm_subnet_id        = "/subscriptions/.../subnets/my-subnet"
  location            = "westus2"

  create_resource_group = false
  create_public_ip      = true
  use_nsg               = true

  admin_username      = "azureuser"
  admin_user_password = "SecureP@ssw0rd!"
  vm_size             = "Standard_DS2_v2"

  tags = {
    environment = "dev"
    project     = "cdp-private-network"
  }
}
```

---

## Resources

| Resource | Description |
|---|---|
| `azurerm_resource_group` | Created only when `create_resource_group = true` |
| `azurerm_public_ip` | Static public IP, created only when `create_public_ip = true` |
| `azurerm_network_interface` | NIC attached to the specified subnet |
| `azurerm_network_security_group` | NSG allowing all inbound TCP, created only when `use_nsg = true` |
| `azurerm_network_interface_security_group_association` | Associates the NSG with the NIC |
| `azurerm_windows_virtual_machine` | Windows 11 Pro (23H2) VM |

---

## Inputs

| Name | Type | Default | Required | Description |
|---|---|---|---|---|
| `vm_name` | `string` | — | **Yes** | Name of the virtual machine. |
| `resource_group_name` | `string` | — | **Yes** | Name of the resource group to deploy into. |
| `vm_subnet_id` | `string` | — | **Yes** | Azure resource ID of the subnet for the VM NIC. |
| `location` | `string` | `"westus2"` | No | Azure region for all resources. |
| `create_resource_group` | `bool` | `false` | No | When `true`, creates the resource group. When `false`, looks up an existing one. |
| `create_public_ip` | `bool` | `false` | No | When `true`, creates and attaches a static public IP to the VM. |
| `use_nsg` | `bool` | `false` | No | When `true`, creates an NSG allowing all inbound TCP and associates it with the NIC. |
| `vm_size` | `string` | `"Standard_DS1_v2"` | No | Azure VM size/SKU. |
| `admin_username` | `string` | `"administrator"` | No | Local administrator username. |
| `admin_user_password` | `string` | `"Passw0rd"` | No | Local administrator password. **Override this — do not use the default in production.** |
| `tags` | `map(string)` | `null` | No | Tags applied to all resources. |

---

## Outputs

| Name | Description |
|---|---|
| `public_ip` | The allocated public IP address, or `null` if `create_public_ip = false`. |
| `private_ip` | The private IP address assigned to the VM's NIC. |

---

## Notes

- **OS image:** Windows 11 Pro 23H2 (`MicrosoftWindowsDesktop/windows-11/win11-23h2-pro/latest`).
- **OS disk:** StandardSSD_LRS with ReadWrite caching.
- **NSG:** When enabled, the NSG permits **all inbound TCP traffic** from any source. This is intentionally permissive for jump-box use cases — tighten the rules for production workloads.
- **Credentials:** The default `admin_user_password` (`Passw0rd`) is a placeholder. Always override it with a strong password, and prefer sourcing it from a secret store (e.g. Azure Key Vault or a Terraform variable marked `sensitive = true`).

---

## Requirements

| Name | Version |
|---|---|
| Terraform | `>= 1.0` |
| `hashicorp/azurerm` | `>= 3.0` |