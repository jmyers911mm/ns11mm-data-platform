# 7.7.0: Single Source Database (ADR-019)

- **Date:** 2026-07-31
- **Version:** 7.7.0

Formalizes what the build already did implicitly: **every environment — sandboxes, shared
dev, CI, and prod — reads RAW/SEEDS source data from the one shared database
`NS11MM_DW_DEV`** while ingestion is seed-based. Decided with Jeremy 2026-07-31; recorded
as ADR-019 (Proposed, committee ratification with the ADR-005 open items).

## Added

- **`docs/adr/ADR_019_single_source_database.md`** — the decision, options considered
  (prod-hosted and per-environment landing set aside, with the end-state noted), risks,
  and the revisit trigger (first production-enabled function pipeline / prod landing /
  2026-12 go-live review). ADR index updated.
- **`scripts/setup_source_grants.sql`** — cross-database read grants: USAGE + SELECT
  (current and future) on `NS11MM_DW_DEV.RAW` / `.SEEDS` for `TRANSFORMER_ROLE`
  (sandboxes + CI) and `DEPLOY_PROD_ROLE` (prod builds). Read-only — RAW stays
  LOADER_ROLE-write-only per ADR-001.

## Changed

- **`seed_database` var → `source_database`** (`dbt_project.yml`, documented in-file;
  `models/raw/sources.yml` ×3, `models/raw/_budget_sources.yml`). The old name suggested
  dbt seeds; the var governs the RAW ingestion database too. Override per-run with
  `--vars '{source_database: <db>}'` only for testing.
- **`gdpr_anonymize` erases where the models read** — the three RAW landing-table updates
  and the erasure log now target `{{ var('source_database') }}` instead of
  `{{ target.database }}`. Before this, an erasure run against a prod or sandbox target
  updated a RAW schema the models were not reading, and the erased PII kept flowing.
  The log is now central: `NS11MM_DW_DEV.INTERMEDIATE.GDPR_ERASURE_LOG`. (The
  `DIM_CUSTOMER` in-place redaction correctly stays per-target.)
- **`cortex_project/cortex-project.yaml`** — DPR semantic-view target corrected
  `NS11MM_DW_DEV_JMYERS.MARTS.DPR` → `NS11MM_DW_DEV.MARTS.DPR` (regression against the
  7.1.0 personal-sandbox eviction; the manifest now matches its own README and the four
  sibling artifacts).
- **Hardcoded-database sweep (portability, same pattern as 7.5.3):**
  `scripts/setup_dpr_narrative.sql` / `setup_retail_narrative.sql` now `USE SCHEMA MARTS`
  against the session database; both `dpr-dashboard` streamlit copies query
  `MARTS.FCT_DAILY_PERFORMANCE` unqualified; `UNIFIED.sv.yaml` verified queries reference
  `MARTS.UNIFIED` (a prod deploy no longer ships verified queries that point at dev);
  both ML notebooks resolve the database from the session
  (`session.get_current_database()`) instead of a literal.
- `docs/architecture/SNOWFLAKE_SETTINGS.md` — `NS11MM_DW_DEV` row notes the
  single-source role and the var.

## Migration notes

1. Run `scripts/setup_source_grants.sql` as SECURITYADMIN (prod's read on shared dev is
   what makes the next prod build work under least privilege).
2. If any wrapper scripts pass `--vars '{seed_database: ...}'`, rename the key to
   `source_database`.
3. No data moves. When ingestion is automated, flip `source_database` per ADR-019's
   revisit trigger.

---
