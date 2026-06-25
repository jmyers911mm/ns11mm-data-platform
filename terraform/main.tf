# NS11MM Data Platform — Terraform Root Module
# Orchestrates: Snowflake warehouse, Key Vault, Static Web App, Monitor Alerts

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "~> 0.70"
    }
  }
  backend "azurerm" {
    resource_group_name  = "rg-ns11mm-data-platform"
    storage_account_name = "stns11mmtfstate"
    container_name       = "tfstate"
    key                  = "ns11mm-data-platform.tfstate"
  }
}

module "snowflake_warehouse" {
  source          = "./modules/snowflake-warehouse"
  warehouse_name  = var.warehouse_name
  warehouse_size  = var.warehouse_size
  credit_quota    = var.credit_quota
  alert_email     = var.alert_email
}

module "key_vault" {
  source              = "./modules/key-vault"
  resource_group_name = var.resource_group_name
  location            = var.location
  key_vault_name      = var.key_vault_name
  pipeline_sp_object_id = var.pipeline_sp_object_id
  admin_object_id     = var.admin_object_id
}

module "static_web_app" {
  source              = "./modules/static-web-app"
  resource_group_name = var.resource_group_name
  location            = var.location
  app_name            = var.static_web_app_name
}

module "monitor_alerts" {
  source              = "./modules/monitor-alerts"
  resource_group_name = var.resource_group_name
  warehouse_name      = module.snowflake_warehouse.warehouse_name
  teams_webhook_url   = var.teams_webhook_url
  alert_email         = var.alert_email
}
