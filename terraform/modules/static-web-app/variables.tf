variable "app_name" {
  description = "Name of the Azure Static Web App hosting the dbt docs"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group the Static Web App is created in"
  type        = string
}

variable "location" {
  description = "Azure region for the Static Web App"
  type        = string
  default     = "eastus"
}
