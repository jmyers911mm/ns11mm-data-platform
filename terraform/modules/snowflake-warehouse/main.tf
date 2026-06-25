resource "snowflake_warehouse" "ns11mm" {
  name           = var.warehouse_name
  warehouse_size = var.warehouse_size
  auto_suspend   = 60
  auto_resume    = true
  comment        = "NS11MM data platform warehouse"
}

resource "snowflake_resource_monitor" "ns11mm" {
  name         = "${var.warehouse_name}_MONITOR"
  credit_quota = var.credit_quota

  notify_triggers        = [75, 90]
  suspend_triggers       = [100]
  suspend_immediate_triggers = [110]

  notify_users = [var.alert_email]
}

output "warehouse_name" {
  value = snowflake_warehouse.ns11mm.name
}
