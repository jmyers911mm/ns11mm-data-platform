resource "azurerm_key_vault" "ns11mm" {
  name                        = var.key_vault_name
  location                    = var.location
  resource_group_name         = var.resource_group_name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  soft_delete_retention_days  = 90
  purge_protection_enabled    = true
  enable_rbac_authorization   = true
}

data "azurerm_client_config" "current" {}

# Admin access (Key Vault Administrator)
resource "azurerm_role_assignment" "admin" {
  scope                = azurerm_key_vault.ns11mm.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = var.admin_object_id
}

# Pipeline service principal access (Key Vault Secrets User — read only)
resource "azurerm_role_assignment" "pipeline_sp" {
  scope                = azurerm_key_vault.ns11mm.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.pipeline_sp_object_id
}

output "key_vault_uri" {
  value = azurerm_key_vault.ns11mm.vault_uri
}
