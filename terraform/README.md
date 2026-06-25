# Terraform — NS11MM Data Platform IaC

## Prerequisites
- Terraform >= 1.5
- Azure CLI authenticated (`az login`)
- Snowflake credentials as environment variables

## Usage

```bash
cd terraform

# Initialize
terraform init

# Plan for dev
terraform plan -var-file="environments/dev.tfvars.json"

# Apply for dev
terraform apply -var-file="environments/dev.tfvars.json"
```

## Deployment order
1. `rg-ns11mm-data-platform` resource group (manual, one-time)
2. `stns11mmtfstate` storage account for Terraform state (manual, one-time)
3. `terraform apply -var-file="environments/dev.tfvars.json"` — provisions all dev resources
4. Staging and prod are manually triggered deployments (see pipelines/)
