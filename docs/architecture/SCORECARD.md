# Platform Scorecard

*Source: NS11MM Data Platform — Production Review v5 (July 7, 2026), updated in the 2026-07-29 documentation truth sweep. Contains only the sections badged "Assessment": Platform Scale & Coverage, and Production Readiness — Dimension Review.*

## Platform Scale & Coverage

| Metric | Value |
|---|---|
| dbt Models (active) | 104 (+53 disabled scaffolds) |
| Test Assertions | see [TEST_ORCHESTRATION.md](TEST_ORCHESTRATION.md) — 12 active singular tests + per-model schema tests |
| Metrics (Semantic) | 49 (MARTS.DPR semantic view; RETAIL/ATTENDANCE/UNIFIED carry their own metric sets) |
| Seed References | 19 |
| ADRs | 7 files (see the register in `docs/adr/README.md`) |
| ML Features | 2 active (+12 disabled scaffolds) |

## Production Readiness — Dimension Review

| Dimension | Grade | Assessment |
|---|---|---|
| Architecture | A | Medallion-pattern layering (conceptual; real schemas STAGING/INTERMEDIATE/MARTS) with RAW immutability, views for staging/intermediate (4 hot intermediates as tables), full-rebuild marts, and reports as views. `on_schema_change`/merge retained as opt-in defaults for models that go incremental. |
| Testing | A− | 12 active singular tests across business rules (7: no-negatives, date coverage, 15-table not-empty, warn-severity `alert_` monitoring), reconciliation (4: ticket/revenue/retail/report-formula matching), and referential integrity (1: orphan-date check), plus schema tests on keys and categoricals. Custom generic-test library exists but is not yet adopted in any `schema.yml`. |
| CI/CD | A− | GitHub Actions two-job pipeline in dedicated `NS11MM_DW_DEV_CI`: sqlfluff lint + compile, then `dbt build --select state:modified+` (slim when a main manifest exists), dbt-snowflake 1.9.*. Pre-commit semantic-view DDL drift guard. Missing: git-secrets pre-commit hook to prevent credential re-exposure. |
| Governance | A− | CODEOWNERS at `.github/CODEOWNERS` (GitHub-enforced). Tier 1/2 change gate documented. Deprecation markers on legacy models. PII classified via groups and masking policies. |
| Semantic Layer | A | 49 DPR metrics authored in `cortex_project/DPR.sv.yaml` (single source of truth) with generated, drift-guarded native DDL twins. Semantic views built on the fact layer to prevent double-aggregation. Cortex Analyst integration with observability logging. |
| Observability | A− | Query tags per layer (`dbt_ns11mm_*`) for cost attribution. Audit log on every run. Cortex questions logged. Note: all 5 MONITORING alerts are suspended as of 6.1.0 pending resource-monitor fix validation (see SNOWFLAKE_SETTINGS). No snapshots are configured. |
| ML Pipeline | B | 2 live feature tables (ticket demand, visitor forecast training) feeding Snowflake ML FORECAST; the other 12 feature scaffolds are disabled pending upstream domains. |
| Developer Experience | A | Per-developer isolated workspaces. Full CONTRIBUTING.md with workflow, change gate, and pre-PR checklist. Terraform IaC for warehouses/alerts. `.sqlfluff` style enforcement in CI. `profiles.yml.template` for setup. |
| Documentation | A− | README, CONTRIBUTING, and architecture guides re-verified against the tree in the 2026-07-29 truth sweep (counts, model names, materializations, links). ADR framework in place with a live register. |
| Security | B− | profiles.yml **removed from the repo** (template-based setup; gitignored) and the exposed PAT file deleted. Masking policies on PII columns; Key Vault for pipeline credentials; Snowflake MFA enforced; `rpt_wifi_email_export` grants opt-out. Remaining gap: automated secret scanning (git-secrets / GitHub secret scanning) still to add — held at B− until that lands. |
