# 7.1.0: Prod Pathing & PII Governance

- **Date:** 2026-07-29
- **Version:** 7.1.0

## Changed

- **`models/raw/sources.yml`** — all three raw source groups resolve via
  `{{ target.database }}` instead of a hardcoded personal dev database. A prod deploy no
  longer reads a developer sandbox; matches the pattern the other source files already used.
- **Cortex project, DPR dashboard, scripts** — semantic views, the agent, both Streamlit app
  copies, semantic-view deploy SQL, narrative setup, and `MANUAL_ML_RUN.sql` now target
  shared dev (`NS11MM_DW_DEV`) rather than a personal sandbox.
- **`pipelines/shared/`** — Key Vault URL, Snowflake database, and warehouse are env-var
  selectable (`NS11MM_KEYVAULT_URL`, `NS11MM_SNOWFLAKE_DATABASE`, `NS11MM_SNOWFLAKE_WAREHOUSE`);
  ingestion defaults to `SOURCES_WH` per SNOWFLAKE_SETTINGS (was hardcoded `COMPUTE_WH`).
- **Narrative tasks** (`scripts/setup_*_narrative.sql`) run on `MONITORING_WH`.
- **Grants** — marts/ml read access moved from post-hooks to dbt `grants` config so models
  can override the default.

## Fixed

- **`rpt_wifi_email_export` no longer inherits BI/ML grants** — `grants: {select: []}`
  overrides the marts default; POWERBI_ROLE / ML_ROLE do not receive the PII export (its own
  header required this; the inherited hook violated it).
- **`apply_masking_policies` / `apply_governance_tags` actually work** — target lists rebuilt
  from the active model estate (`stg_wifi__audience`, `stg_ecommerce__website_recurring`,
  `int_pos_tickets`, `dim_customer`, `rpt_wifi_email_export`, plus the live marts). The old
  lists named pre-rename POC and disabled objects, so the existence checks no-opped every
  entry and nothing was ever masked or tagged. View-vs-table ALTER handled; policy/tag
  database parameterized via vars.
- **`scripts/MANUAL_ML_RUN.sql`** referenced `dim_date` columns that don't exist
  (`date_id` → `date_key`, `fiscal_year` → `year_number`) — could not have run as written.

## Docs

- `docs/architecture/DATA_CLASSIFICATION.md` PII inventory rewritten to the live surfaces,
  with an explicit keep-in-sync rule binding it to the masking/tagging macros.

---
