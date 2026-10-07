# 1.2.0: Best Practices, Security & Monitoring

- **Date:** 2026-06-25
- **Version:** 1.2.0

*Errata (2026-07-29): the version number 1.2.0 was used twice. This is the second (later) 1.2.0, dated 2026-06-25; the earlier 1.2.0 dated 2026-06-23 ("dbt Platform Foundation") appears further down. Entries are kept as written — disambiguate by date.*

## Added
- `NS11MM_DW_DEV.MONITORING` schema — alerts, tasks, audit views, DMFs
- 5 active alerts: source freshness, dbt failures, warehouse utilization, credit consumption, long-running queries
- `MANAGE_ALERTS` stored procedure — suspend/resume alerts individually or all at once
- 4 scheduled tasks: daily dbt build (6 AM), freshness check (5:30 AM), weekly PROD clone (Sun 2 AM), weekly docs generate (Mon 7 AM)
- 3 masking policies: MASK_NAME, MASK_EMAIL, MASK_PHONE (DEV + PROD)
- Row access policy: RAP_PII_ACCESS (ML_ROLE filtered from PII rows)
- Network policy: NS11MM_NETWORK_POLICY (created, NOT activated — test first)
- 3 governance tags: SENSITIVITY, DATA_DOMAIN, DATA_OWNER
- 4 Data Metric Functions: DMF_NULL_RATE, DMF_ROW_COUNT, DMF_DUPLICATE_RATE, DMF_FRESHNESS_HOURS
- `macros/operations/apply_masking_policies.sql` — auto-applies masking on-run-end
- `macros/operations/apply_governance_tags.sql` — auto-applies tags on-run-end
- `macros/operations/create_raw_streams.sql` — creates CDC streams on RAW tables
- `.github/workflows/dbt-ci.yml` — CI workflow for PR validation
- `docs/DATA_CONTRACTS.yml` — freshness SLAs, quality thresholds, refresh targets
- `models/exposures.yml` — expanded with 5 Power BI dashboards, 3 Cortex Analyst views, 3 ML models
- 2 Snowflake secrets: SECRET_POWERBI_SVC, SECRET_LOADER_SVC (rotate immediately)
- Deployed dbt project: `NS11MM_DW_DEV.PUBLIC.NS11MM_DATA_PLATFORM`

## Changed
- `DEPLOY_DEV_ROLE` and `DEPLOY_PROD_ROLE` created with proper hierarchy
- Old roles removed: `DBT_DEV_ROLE`, `DBT_PROD_ROLE`
- `MUSEUM_DW_DEV` database dropped (old POC)
- `NS11MM_DW_DEV_KRAMSEY` database dropped
- All old schemas removed from JMYERS and PROD (BRONZE, SILVER, GOLD, etc.)
- NS11MM_DW_DEV time travel increased to 7 days
- Warehouse auto_suspend: MONITORING/SOURCES/DBT_DEV reduced to 30s
- Statement timeouts set on all warehouses (5–60 min based on workload)
- POWERBI_SVC: query_tag set to 'powerbi_reporting'
- `dbt_project.yml`: added `on-run-end` hooks for tags + masking
- LOADER_ROLE: granted write to RAW in DEV + PROD
- POWERBI_ROLE: granted SELECT + future grants on MARTS (PROD)
- ML_ROLE: granted SELECT INTERMEDIATE/MARTS + WRITE ML_FEATURES

## Documentation Updated
- `SNOWFLAKE_SETTINGS.md` — complete rewrite reflecting current state
- `docs/README.md` — schema table updated with STAGING layer
- `docs/ONBOARDING.md` — RBAC roles, profiles.yml note for Snowflake-native
- `docs/architecture/DATA_CLASSIFICATION.md` — updated PII locations, masking policies, role-based access table
- `docs/architecture/TEST_ORCHESTRATION.md` — updated source names and freshness thresholds
- `docs/architecture/SQL_STYLE_GUIDE.md` — updated naming convention table
- `docs/architecture/SOURCE_INTEGRATION.md` — terminology (Bronze → RAW)
- `docs/architecture/USAGE_AUDIT.md` — added pre-built monitoring views section
- `docs/business/METRIC_GLOSSARY.md` — fiscal year corrected to October start
- `macros/operations/README.md` — added all new macros + on-run-end hooks
- `macros/data_quality/README.md` — updated freshness thresholds
- `RUNBOOK.md` — added GDPR, governance, alert management, and deployed dbt project commands
- `PLATFORM_SCORECARD.md` — new file: best-in-class assessment (9.3/10), architecture diagram, role hierarchy, monitoring stack, industry comparison

---
