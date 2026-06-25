output "key_vault_uri" {
  description = "URI of the provisioned Key Vault"
  value       = module.key_vault.key_vault_uri
}

output "warehouse_name" {
  description = "Name of the provisioned Snowflake warehouse"
  value       = module.snowflake_warehouse.warehouse_name
}

output "static_web_app_hostname" {
  description = "Hostname of the dbt docs Static Web App"
  value       = module.static_web_app.hostname
}
