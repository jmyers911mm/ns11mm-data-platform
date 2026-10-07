# 1.0.0

- **Date:** 2026-06-23
- **Version:** 1.0.0

## Initial production repository setup

- Created `ns11mm/ns11mm-data-platform` as the production repository, replacing POC repo `jmyers911mm/ns11mm-dbt`
- Established medallion architecture: RAW (Bronze) / staging / intermediate / marts naming convention
- Configured `dbt_project.yml` for `ns11mm_data_platform` project
- Configured `profiles.yml` with dev target (`NS11MM_DW_DEV`) and prod target (`NS11MM_DW_PROD`)
- Established PR-gated CI/CD as the required deployment pattern for all model changes
- Snowflake workspace: `NS11MM_DW_DEV.PUBLIC."ns11mm-dbt"` (shared dev environment)
- Personal dev databases: `NS11MM_DW_DEV_JMYERS` (Jeremy), `NS11MM_DW_DEV_KRAMSEY` (Kalea)

## Governance baseline

- ADR register established (ADR-001 through ADR-017)
- ADR-005: Metric Definition Gate — metric approval required before any Gold model is built
- ADR-006: Change Management Framework — tiered change management (Tier 1 / Tier 2 / Emergency)
- Bronze/RAW layer: immutable, append-only — architectural constraint enforced by design
- All business logic in dbt; Power BI is display-only

---
