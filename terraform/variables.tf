variable "location" {
  description = "The Azure region to deploy resources in."
  type        = string
  default     = "UAE North"
}

variable "resource_group_name" {
  description = "The name of the resource group to create."
  type        = string
  default     = "rg-cloudsec-lab-dev"
}

variable "vm_size" {
  description = "The size of the Virtual Machine to create."
  type        = string
  default     = "Standard_D2s_v3"
}

variable "admin_username" {
  description = "The admin username for the Virtual Machine."
  type        = string
  default     = "azureuser"
}