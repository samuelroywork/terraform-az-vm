variable "prefix" {
  description = "Prefix used for naming all resources"
  type        = string
  default     = "tfazvm"
}

variable "location" {
  description = "Azure region to deploy resources into"
  type        = string
  default     = "southeastasia"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-tfazvm"
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_address_prefixes" {
  description = "Address prefixes for the VM subnet"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "vm_size" {
  description = "Size (SKU) of the virtual machine"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key used for VM admin access"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "allowed_ssh_source" {
  description = "CIDR or IP allowed to reach the VM over SSH (use your own IP, e.g. 203.0.113.5/32)"
  type        = string
  default     = "*"
}

variable "os_disk_type" {
  description = "Storage account type for the OS disk"
  type        = string
  default     = "Standard_LRS"
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default = {
    environment = "dev"
    managed_by  = "terraform"
  }
}
