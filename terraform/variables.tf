variable "resource_group_name" {
  description = "Azure resource group for NS11MM data platform resources"
  type        = string
  default     = "rg-ns11mm-data-platform"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "key_vault_name" {
  description = "Azure Key Vault name for pipeline credentials"
  type        = string
  default     = "kv-ns11mm-dp-dev"
  validation {
    condition     = length(var.key_vault_name) <= 24
    error_message = "Key Vault name must be 24 characters or fewer."
  }
}

variable "warehouse_name" {
  description = "Snowflake warehouse name"
  type        = string
  default     = "DBT_DEV_WH"
}

variable "warehouse_size" {
  description = "Snowflake warehouse size"
  type        = string
  default     = "X-SMALL"
}

variable "credit_quota" {
  description = "Monthly credit quota for resource monitor"
  type        = number
  default     = 5
}

variable "alert_email" {
  description = "Email for credit and pipeline alerts"
  type        = string
  default     = "jmyers@911memorial.org"
}

variable "static_web_app_name" {
  description = "Azure Static Web App name for dbt docs"
  type        = string
  default     = "stapp-ns11mm-dbt-docs"
}

variable "teams_webhook_url" {
  description = "Microsoft Teams webhook URL for credit alerts"
  type        = string
  sensitive   = true
}

variable "pipeline_sp_object_id" {
  description = "Object ID of the pipeline service principal for Key Vault access"
  type        = string
}

variable "admin_object_id" {
  description = "Object ID of the admin user (Jeremy) for Key Vault management"
  type        = string
}
