resource "azurerm_static_web_app" "dbt_docs" {
  name                = var.app_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku_tier            = "Free"
  sku_size            = "Free"
}

output "hostname" {
  value = azurerm_static_web_app.dbt_docs.default_host_name
}
