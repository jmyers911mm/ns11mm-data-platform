# 1.3.2: Doc Cleanup

- **Date:** 2026-07-06
- **Version:** 1.3.2

## Documentation Review — Current-Scope Accuracy Pass

Reviewed all 39 `.md` files in `ns11mm/ns11mm-data-platform` against the actual repo state
(models enabled vs. `enabled=false`, real folder names, real file names). **22 files changed.**

Ground truth used: **live today = the Gateway + CounterPoint → Daily Performance Report slice**
(21 staging, 8 intermediate, 4 dims + 1 fact + 1 report, 1 semantic view). Everything else is
present but `enabled=false`. This zip contains only the changed files, at their repo paths.

---

### Two systemic problems fixed

1. **Orphaned Git merge-conflict markers.** 54 stray `>>>>>>> remote` lines across 16 files
   (no matching `<<<<<<<`/`=======` halves — content was intact). All removed. Files affected
   by *marker removal only*: `CHANGELOG.md`, `SNOWFLAKE_SETTINGS.md`, `docs/ONBOARDING.md`,
   `docs/architecture/DATA_CLASSIFICATION.md`, `SQL_STYLE_GUIDE.md`, `USAGE_AUDIT.md`,
   `macros/data_quality/README.md`, `macros/generic_tests/README.md`.

2. **Docs presenting the full future platform as if it's live today**, with no current-vs-planned
   distinction (the issue you flagged on the main README + customer 360).

---

### Substantive changes

- **README.md** — rewritten. Added a "Current scope: live today vs. planned" banner with a
  live/total counts table; corrected the "96 models" claim; fixed the Project Structure tree to
  the real folders (`models/raw`, `models/intermediate`, `models/marts/{dimensions,facts,reports}`
  — not `staging/silver/gold`); replaced fictional model names and lineage
  (`stg_gateway__transactions`, `fct_ticket_sales`, `rpt_ticket_sales`) with the real DPR chain;
  marked Identity Resolution, the 4 semantic views, the Cortex agent, and the VQR library as
  **[PLANNED]** and corrected to the single live `MARTS.DPR` view; fixed the fiscal-year
  contradiction.

- **docs/architecture/PROJECT_MAP.md** — fixed all `models/staging|silver|gold/` paths to
  `raw|intermediate|marts`; replaced the fictional reference chain and the mental-model diagram
  with the real live DPR flow; corrected the repository-map counts to live/total; marked deleted
  items (exposures placeholder, snapshots planned, `verified_queries` removed); pointed the seeds
  and semantic_models rows at what's actually there; added a scope banner.

- **docs/business/README.md** — added a "what's available today" banner; annotated the dashboard
  finder with Live/(planned) status (only the Daily Performance Report is live); corrected the
  claim that every area already has a dashboard.

- **PLATFORM_SCORECARD.md** — added a scope note; corrected "4 semantic views" → 1 live DPR view;
  noted the VQR library was removed.

- **semantic_models/README.md** — fixed the file names (`dpr_semantic_view.sql` →
  `create_dpr_semantic_view.sql`; `dpr_semantic_model.yaml` → `dpr.yaml`) and the object name
  (`NS11MM_DP.MARTS.DPR` → `MARTS.DPR`, portable via `USE DATABASE`).

- **Scope banners added** (forward-looking docs that were otherwise fine): `docs/README.md`,
  `docs/architecture/ARCHITECTURE_FLOW.md`, `SOURCE_INTEGRATION.md`, `TEST_ORCHESTRATION.md`,
  `docs/business/METRIC_GLOSSARY.md`.

- **Concrete stale-reference fixes:** `CONTRIBUTING.md` (VQR workflow marked [PLANNED], notes the
  library was removed in 1.3.1); `macros/operations/README.md` (`sync_verified_queries` marked
  inactive); `GATEWAY_COUNTERPOINT_SCHEMA_REQUEST.md` (`models/staging/` → `models/raw/`);
  `RUNBOOK.md` (example command repointed from `fct_ticket_sales` to the live `fct_daily_performance`).

---

### Left unchanged (already accurate)

- **The six model-folder READMEs** (`models/raw`, `models/intermediate`, `models/marts/dimensions`,
  `.../facts`, `.../reports`, `models/ml_features`) — these already list Enabled vs. Disabled
  models correctly with blocker/re-enable reasons. Verified each against the actual model configs;
  they match exactly. These are the authoritative per-model source of truth, and the rewritten
  top-level docs now point to them.
- **ADRs, tests/* READMEs, pipelines/readme, terraform/README** — accurate or forward-looking by
  design; no current-vs-planned misrepresentation after marker cleanup.

---

### One thing to confirm

The main README now says to **confirm the fiscal start month**, while `METRIC_GLOSSARY.md` asserts
**October** (FY = Oct–Sep). `dim_date` has `fiscal_year`/`fiscal_month` logic. If October is
correct, the README can be made assertive to match the glossary.
