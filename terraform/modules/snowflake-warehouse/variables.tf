variable "warehouse_name" {
  description = "Name of the Snowflake warehouse to provision"
  type        = string
}

variable "warehouse_size" {
  description = "Snowflake warehouse size (e.g. X-SMALL, SMALL, MEDIUM)"
  type        = string
  default     = "X-SMALL"
}

variable "credit_quota" {
  description = "Monthly credit quota for the warehouse resource monitor"
  type        = number
}

variable "alert_email" {
  description = "Snowflake user/email notified by the resource monitor triggers"
  type        = string
}
