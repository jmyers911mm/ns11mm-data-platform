# 1.5.2: Developer Onboarding & Semantic View Pipeline

- **Date:** 2026-07-13
- **Version:** 1.5.2

## Added

- **Parameterized developer workspace setup** (`scripts/setup_developer_workspace.sql`):
  change one `SET dev_username` variable to provision a full dev environment (database,
  schemas, grants). Eliminates manual find-and-replace of hardcoded usernames.
- **Pre-commit hook** (`.githooks/pre-commit`): auto-regenerates
  `create_dpr_semantic_view.sql` from `dpr.yaml` whenever the YAML or generator is staged,
  ensuring the DDL never drifts from the metric definitions.
- **BUILD_DIMS_METS.md** updated with documentation on the YAML→SQL pipeline, ratio-of-sums
  semantics for `avg_ticket_price`, and how `assert_rpt_avg_ticket_price.sql` guards against
  formula drift in the `rpt_` layer.

## Changed

- `dpr.yaml`: removed duplicate `avg_ticket_price` definition; canonical ratio now lives once
  in the NON-ADDITIVE RATIOS section as `SUM(TOTAL_ADMISSION_REVENUE) / NULLIF(SUM(TICKETS_SOLD), 0)`.
- `setup_developer_workspace.sql`: split `INSERT, CREATE TABLE ON SCHEMA` (invalid) into
  separate `CREATE TABLE ON SCHEMA` + `INSERT ON FUTURE/ALL TABLES` grants.

## Fixed

- KRAMSEY dev database: granted `ALL ON ALL TABLES` and `ALL ON FUTURE TABLES` in
  `NS11MM_DW_DEV_KRAMSEY.RAW` to `TRANSFORMER_ROLE` — tables created by ACCOUNTADMIN were
  invisible to `DEPLOY_DEV_ROLE` (which inherits TRANSFORMER_ROLE).
- KRAMSEY default role set to `DEPLOY_DEV_ROLE`.
- Copied all 22 RAW tables from `NS11MM_DW_DEV_JMYERS` to `NS11MM_DW_DEV_KRAMSEY`.

---
