variable "key_vault_name" {
  description = "Name of the Azure Key Vault (max 24 characters)"
  type        = string
}

variable "location" {
  description = "Azure region for the Key Vault"
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Resource group the Key Vault is created in"
  type        = string
}

variable "admin_object_id" {
  description = "Entra ID object ID of the admin user granted Key Vault Administrator"
  type        = string
}

variable "pipeline_sp_object_id" {
  description = "Entra ID object ID of the pipeline service principal granted Key Vault Secrets User (read-only)"
  type        = string
}
