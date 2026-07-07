# terraform-az-vm

Terraform configuration that deploys a single Ubuntu 24.04 LTS virtual machine
on Microsoft Azure, together with all the network infrastructure it needs.

## What gets deployed

8 resources, all named with a configurable prefix (default `tfazvm`):

```
Resource Group (rg-tfazvm)
└── Virtual Network 10.0.0.0/16
    └── Subnet 10.0.1.0/24  ←— Network Security Group (SSH allowed from one IP only)
        └── Network Interface ←— Static Public IP (Standard SKU)
            └── Linux VM — Ubuntu 24.04 LTS Gen2, Standard_D2s_v3 (2 vCPU / 8 GB)
```

- SSH-key-only authentication (password login disabled)
- Inbound SSH restricted to a single source IP via NSG rule
- Default region: `eastasia` (configurable)

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) ≥ 1.5
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) logged in (`az login`)
- An RSA SSH key pair (`ssh-keygen -t rsa -b 4096` if you don't have one) —
  Azure's `admin_ssh_key` accepts RSA keys only, not ed25519
- One-time per subscription — register the resource providers this config uses
  (automatic registration is disabled in `providers.tf` to keep plans fast):

  ```bash
  az provider register --namespace Microsoft.Compute --wait
  az provider register --namespace Microsoft.Network --wait
  az provider register --namespace Microsoft.Storage --wait
  ```

## Quick start

```bash
# 1. Authenticate and select the subscription
az login
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# 2. Configure — set your own IP in allowed_ssh_source, check the key path
cp terraform.tfvars.example terraform.tfvars

# 3. Deploy
terraform init
terraform plan
terraform apply

# 4. Connect (exact command is in the outputs)
terraform output ssh_command
ssh azureuser@<public-ip>
```

## Configuration

All variables have defaults; override them in `terraform.tfvars`.

| Variable | Default | Description |
|---|---|---|
| `prefix` | `tfazvm` | Naming prefix for all resources |
| `location` | `eastasia` | Azure region |
| `resource_group_name` | `rg-tfazvm` | Resource group name |
| `vm_size` | `Standard_D2s_v3` | VM SKU (see [Choosing a VM size](#choosing-a-vm-size)) |
| `admin_username` | `azureuser` | Admin account on the VM |
| `ssh_public_key_path` | `~/.ssh/id_rsa.pub` | RSA public key authorized on the VM |
| `allowed_ssh_source` | `*` | CIDR allowed to SSH in — **set this to your own IP**, e.g. `203.0.113.5/32` |
| `os_disk_type` | `Standard_LRS` | OS disk storage type |
| `tags` | `dev` / `terraform` | Tags applied to every resource |

Outputs after apply: `public_ip_address`, `private_ip_address`, `vm_name`,
`resource_group_name`, and a ready-to-paste `ssh_command`.

## Choosing a VM size

Two constraints learned the hard way:

1. **Regional capacity** — a size can exist in Azure but be unavailable in your
   region (`SkuNotAvailable`). Check before changing `vm_size`:

   ```bash
   az vm list-skus --location <region> --size <size> --output table
   ```

2. **Hypervisor generation** — the Ubuntu 24.04 image used here is
   **Generation 2** (UEFI). Older sizes such as `D2_v3` only boot Gen1 and fail
   with a `BadRequest` error. Stick to Gen2-capable sizes (most `s`-suffixed
   sizes: `D2s_v3`, `B2s_v2`, `D2s_v5`, …).

## Costs

`Standard_D2s_v3` costs roughly **US$0.11–0.13/hour** (~US$85/month) in
eastasia, plus a few dollars for the disk and public IP. Destroy the
infrastructure when you're not using it:

```bash
terraform destroy
```

## Troubleshooting

| Error | Cause | Fix |
|---|---|---|
| `subscription_id is a required provider property` | azurerm v4 requires an explicit subscription | `export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)` (per shell session) |
| `MissingSubscriptionRegistration` / API-version-not-found | Resource providers not registered (auto-registration is off) | Run the three `az provider register` commands from Prerequisites |
| `SkuNotAvailable` (409) | No capacity for that size in the region | Pick another size (`az vm list-skus`) or region |
| `cannot boot Hypervisor Generation '2'` (400) | Gen1-only VM size with the Gen2 image | Use a Gen2-capable size (e.g. `D2s_v3`) |
| `InvalidResourceReference` / state out of sync | An interrupted apply left state drift | Compare `terraform state list` with `az resource list`; repair with `terraform import` / `terraform state rm`. Avoid Ctrl+C during applies |

## Repository layout

```
providers.tf              # Terraform + azurerm provider requirements
variables.tf              # Input variables and defaults
main.tf                   # All 8 resources
outputs.tf                # IPs, VM name, ssh command
terraform.tfvars.example  # Copy to terraform.tfvars and customize
.terraform.lock.hcl       # Provider version lock (committed on purpose)
```

`terraform.tfvars` and all state files are git-ignored — they contain your IP
address and full infrastructure details. Never commit them.
