# 7.5.0: Documentation Truth Sweep

- **Date:** 2026-07-29
- **Version:** 7.5.0

Docs now describe the repo as it is. `dbt_project.yml` version aligned to this changelog
(it had stayed at 1.0.0 since initial setup).

## Changed

- **Inventory docs regenerated from the tree** — root README scope tables (34 staging /
  21 intermediate / 13 dims / 11 facts / 23 reports / 2 ML / 19 seeds / 12 tests / 4 semantic
  views); every `models/*/README.md` (the dimensions README's enabled and disabled lists were
  fully inverted); tests READMEs list all 12 active tests; retired `silver_*` names replaced
  throughout; `ARCHITECTURE_FLOW.md` rewritten from scratch (previous content described a
  pre-1.3.0 repo that no longer exists); PROJECT_MAP, TEST_ORCHESTRATION, SCORECARD,
  SOURCE_INTEGRATION (retail POS confirmed as NCR CounterPoint; Fabric references removed),
  SNOWFLAKE_SETTINGS (SEEDS schema, alerts marked SUSPENDED per 6.1.0), USAGE_AUDIT,
  SQL_STYLE_GUIDE (int_* convention, `_key` keys, the real sqlfluff ruleset) all corrected.
- **ADR record made coherent** — `ADR_018_metric_defintion_ownership.md` renamed (typo);
  index rebuilt over the 7 in-repo ADRs with the external-register numbering note (007–017;
  007/008 collision tracked, owner Jeremy); ADR-018 §3 amended (pending committee
  ratification) to exempt thin serving chains off `rpt_*_powerbi` / `rpt_*_budget_daily` —
  governance and code no longer disagree.
- **`CODEOWNERS` moved to `.github/CODEOWNERS`** (a location GitHub honors) with path
  patterns fixed — the reviewer gate is now enforceable.
- **CONTRIBUTING / ONBOARDING runnable again** — real CI description, ownership zones from
  `groups.yml`, Time Travel 7 days, corrected rollback recipe, Python 3.11 /
  dbt-snowflake 1.9.*, `dev_shared` target, template-based profile setup, `core.hooksPath`
  step, smoke tests that execute (`dim_facility`, `date_key`).
- **`docs/DATA_CONTRACTS.yml`** rewritten for the live marts with source-matched freshness
  SLAs; **`docs/REFRESH_LOG.md`** reset to a truthful empty log (the logged runs could not
  have been produced by the current code); **DQI-0001** repointed at the real artifact names;
  policy docs aligned on the "AI & Data Committee" name; remaining Fabric references removed;
  `pipelines/readme.md` → `pipelines/README.md`; `macros/generic_tests/` filenames
  standardized (unused `test_` prefixes dropped) and the library honestly marked
  available-but-unadopted; exposures meta repointed at live models.

## Reconciliation

History that previous entries missed, recorded here rather than by rewriting them:

- `dim_marketing_channel` was removed from the repo after its 4.1.0 re-enable, with no
  changelog entry at the time. Its seed `ref_marketing_channels` remains.
- `dim_dpr_line_item` and `dim_retail_line_item` were added, together with their
  `dpr_line_items.csv` / `retail_line_items.csv` seeds, without a changelog entry.
- The `rpt_*_powerbi` / `rpt_*_report_long` / `rpt_*_budget_daily` report family (DPR and
  Retail serving chains) was added without a dedicated changelog entry.
- The WiFi feed (`stg_wifi__audience` and downstream `rpt_wifi_email_export`) was loaded
  without a dedicated changelog entry.
- Errata annotations added to the duplicated `[1.2.0]` / `[1.1.0]` entries and to
  4.1.0/4.2.0 (see those entries).

---
