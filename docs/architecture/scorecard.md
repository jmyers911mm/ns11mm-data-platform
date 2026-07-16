# Assessment

*Source: NS11MM Data Platform — Production Review v5 (July 7, 2026). Contains only the sections badged "Assessment": Platform Scale & Coverage, and Production Readiness — Dimension Review.*

## Platform Scale & Coverage

| Metric | Value |
|---|---|
| dbt Models | 100 |
| Test Assertions | 82 |
| Metrics (Semantic) | 36 |
| Seed References | 8 |
| ADRs (Active) | 4 |
| ML Features | 14 |

## Production Readiness — Dimension Review

| Dimension | Grade | Assessment |
|---|---|---|
| Architecture | A | Medallion pattern correctly implemented with RAW immutability, incremental merge on silver/gold, full-rebuild dimensions, `on_schema_change`, and hashdiff change detection throughout. |
| Testing | A | 82 test assertions across business rules (volume, no-negatives, date coverage), reconciliation (ticket/revenue matching), and referential integrity (FK checks, orphan detection). Custom generics for outlier and distribution detection. |
| CI/CD | A− | GitHub Actions with `dbt build` (models + tests unified). Slim CI on `state:modified+` for efficiency. Pre-hook timeout logic correct. Pre-PR checklist documented. Missing: git-secrets pre-commit hook to prevent credential re-exposure. |
| Governance | A− | CODEOWNERS covers all paths (relocated to `docs/architecture/`). Tier 1/2 change gate documented. Deprecation markers on legacy models. PII classified via groups and masking policies. Gap: CODEOWNERS should move to `.github/` for GitHub enforcement. |
| Semantic Layer | A | 36 certified metrics across DPR, each with stakeholder owner, ADR reference, and approval metadata. Semantic view built on fact layer to prevent double-aggregation. Cortex Analyst integration with observability logging. |
| Observability | A | Query tags per layer for cost attribution. Audit log on every run. Cortex questions logged unredacted. Daily gap detection with Teams + email alerts. SCD2 snapshots on CRM for historical states. |
| ML Pipeline | A | 14 feature tables across 7 use cases (churn, optimization, pricing, cross-sell, no-show, propensity, forecasting). All materialized as tables in ML_FEATURES schema, ready for training jobs. |
| Developer Experience | A | Per-developer isolated workspaces. Full CONTRIBUTING.md with workflow, VQR process, change gate, and pre-PR checklist. Terraform IaC for all infrastructure. `.sqlfluff` for style enforcement. |
| Documentation | A− | README, CONTRIBUTING, RUNBOOK, and architecture guides all current. ADR framework in place (ADRs-005/006 decided, 007/008 pending). Data contracts documented. Source audit tracker available in Hub. |
| Security | C | Masking policies on PII columns. Key Vault integration for sensitive configs. Snowflake MFA enforced. **Critical Gap:** profiles.yml committed with credentials. Missing: git-secrets pre-commit hook, CODEOWNERS in `.github/`. Requires immediate remediation. |