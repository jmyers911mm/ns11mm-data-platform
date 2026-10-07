# 1.1.0: Production Git Workspace Migration

- **Date:** 2026-06-24
- **Version:** 1.1.0

*Errata (2026-07-29): the version number 1.1.0 was used twice. This is the second (later) 1.1.0, dated 2026-06-24; the earlier 1.1.0 dated 2026-06-23 ("Bronze Ingestion Pipeline Framework") appears further down. Entries are kept as written — disambiguate by date.*

## Added
- `profiles.yml` for Snowflake-native dbt (no env_var/password/authenticator)
- `models/raw/stg_gateway__customers.sql` — staging model for Gateway customer data
- `models/intermediate/schema.yml` — documentation + tests for all 12 intermediate models
- `models/marts/facts/schema.yml` — documentation + tests for all 22 fact models
- `models/marts/reports/schema.yml` — documentation + tests for all 9 report models
- `models/ml_features/schema.yml` — documentation + tests for all 14 ML feature models
- `semantic_models/ns11mm_marketing_performance.yaml` — SV_MARKETING_PERFORMANCE (6 entities: digital_ad_performance, email_campaigns, website_traffic, website_funnel, channel_summary, dates)
- `semantic_models/ns11mm_marketing_sales.yaml` — SV_MARKETING_SALES (3 entities: marketing_sales_daily, campaign_attribution, dates)
- `notebooks/ml_member_churn_prediction.ipynb` — XGBoost member churn classifier with Snowflake ML Registry integration
- `notebooks/ml_ticket_demand_forecast.ipynb` — XGBoost ticket demand forecaster with Snowflake ML Registry integration
- `macros/operations/gdpr_anonymize.sql` — GDPR right-to-erasure macro; anonymizes PII across INTERMEDIATE + MARTS layers with audit log
- `macros/generic_tests/z_score_outlier.sql` — statistical outlier detection test (configurable z-score threshold)
- `macros/generic_tests/positive_value.sql` — assert column values are non-negative
- `macros/generic_tests/value_between.sql` — assert column values within min/max bounds
- Three-tier RBAC promotion model: TRANSFORMER_ROLE → DEPLOY_DEV_ROLE → DEPLOY_PROD_ROLE

## Fixed
- `silver_sf_crm` — replaced NULL placeholders with actual joins to stg_salesforce_nps__opportunities for membership and donation enrichment
- `silver_blackbaud` — fixed `CASE WHEN null` logic (now uses `CASE WHEN IS NULL`)
- `silver_pos_tickets` — resolved missing customer_email/phone by creating stg_gateway__customers and joining
- `dim_customer` schema.yml — test column corrected from `id` to `customer_id`, added `unique` test
- `dbt_project.yml` — raw models schema changed from `INTERMEDIATE` to `STAGING`
- README fiscal year reference corrected to October start (was July)

## Changed
- `profiles.yml` — `dev_shared` target now uses `DEPLOY_DEV_ROLE`, `prod` uses `DEPLOY_PROD_ROLE`
- `ns11mm_operations.yaml` — expanded with daily_operations + ticket_availability tables (now 5 entities)
- `ns11mm_fundraising_members.yaml` — added donor_retention table (now 5 entities)
- `CONTRIBUTING.md` — added RBAC-enforced promotion workflow, role permissions table, developer targets, emergency hotfix process, updated environment architecture and schema table
- `RUNBOOK.md` — corrected schema reference from GOLD to MARTS
- `docs/architecture/ARCHITECTURE_FLOW.md` — staging layer schema updated to STAGING, model names updated to production naming convention
- `docs/architecture/PROJECT_MAP.md` — reference chain updated from POC single-source pattern to 14-source production pattern

---
