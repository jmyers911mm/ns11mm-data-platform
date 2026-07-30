# Terraform — NS11MM Data Platform IaC

## Prerequisites
- Terraform >= 1.5
- Azure CLI authenticated (`az login`)
- Snowflake credentials as environment variables (`SNOWFLAKE_ACCOUNT`,
  `SNOWFLAKE_USER`, `SNOWFLAKE_PASSWORD`, `SNOWFLAKE_ROLE`)

## State

Each environment has its own state file in the shared `stns11mmtfstate`
storage account. The backend `key` is supplied at init time so environments
never share state:

```bash
terraform init -backend-config="key=ns11mm-data-platform-dev.tfstate"      # dev
terraform init -backend-config="key=ns11mm-data-platform-staging.tfstate"  # staging
terraform init -backend-config="key=ns11mm-data-platform-prod.tfstate"     # prod
```

## Usage

```bash
cd terraform

# Initialize (dev shown; use the matching key per environment)
terraform init -backend-config="key=ns11mm-data-platform-dev.tfstate"

# Required variables not in the tfvars files (secrets / principals):
export TF_VAR_teams_webhook_url='https://...'
export TF_VAR_pipeline_sp_object_id='<sp-object-id>'
export TF_VAR_admin_object_id='<admin-object-id>'

# Plan for dev
terraform plan -var-file="environments/dev.tfvars.json"

# Apply for dev
terraform apply -var-file="environments/dev.tfvars.json"
```

## Modules

Each module under `modules/` declares its inputs in its own `variables.tf`:

- `snowflake-warehouse` — warehouse + resource monitor (`warehouse_name`, `warehouse_size`, `credit_quota`, `alert_email`)
- `key-vault` — RBAC-enabled Key Vault (`key_vault_name`, `resource_group_name`, `location`, `admin_object_id`, `pipeline_sp_object_id`)
- `static-web-app` — dbt docs host (`app_name`, `resource_group_name`, `location`)
- `monitor-alerts` — action group with email + Teams webhook (`resource_group_name`, `alert_email`, `teams_webhook_url`, `warehouse_name`)

## Pipelines (Azure DevOps)

`pipelines/deploy-{dev,staging,prod}.yml`:

- **dev** auto-triggers on merge to `main` (paths filter `terraform/**`).
- **staging** and **prod** are manual: plan (agent job) → `ManualValidation@0`
  approval (server job) → apply (agent job).
- Every pipeline inits with its own `-backend-config="key=..."` state key.
- Each pipeline reads a variable group `ns11mm-terraform-<env>` that must
  contain: `ARM_SUBSCRIPTION_ID`, `ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`
  (secret), `ARM_TENANT_ID`, `TEAMS_WEBHOOK_URL` (secret),
  `PIPELINE_SP_OBJECT_ID`, `ADMIN_OBJECT_ID`, `SNOWFLAKE_ACCOUNT`,
  `SNOWFLAKE_USER`, `SNOWFLAKE_PASSWORD` (secret), `SNOWFLAKE_ROLE`.

## Deployment order
1. `rg-ns11mm-data-platform` resource group (manual, one-time)
2. `stns11mmtfstate` storage account for Terraform state (manual, one-time)
3. dev pipeline (or local `terraform apply -var-file="environments/dev.tfvars.json"`)
4. Staging and prod are manually triggered deployments (see pipelines/)

## Known debt

The Snowflake provider is pinned to `Snowflake-Labs/snowflake ~> 0.70`, which
is the deprecated registry namespace. Migration to `snowflakedb/snowflake`
(current namespace, breaking changes in resource schemas) should be planned;
the pin is deliberately left unchanged until that migration is scoped.
