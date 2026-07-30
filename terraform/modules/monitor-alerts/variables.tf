variable "resource_group_name" {
  description = "Resource group the monitor action group is created in"
  type        = string
}

variable "alert_email" {
  description = "Email address that receives credit and pipeline alerts"
  type        = string
}

variable "teams_webhook_url" {
  description = "Microsoft Teams incoming-webhook URL for alert notifications"
  type        = string
  sensitive   = true
}

variable "warehouse_name" {
  description = "Snowflake warehouse the alerts relate to (passed by the root module; reserved for warehouse-specific alert rules)"
  type        = string
  default     = ""
}
