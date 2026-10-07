# 7.3.0: Semantic Layer: Unique Metrics & Single Generator

- **Date:** 2026-07-29
- **Version:** 7.3.0

## Changed

- **Metric renames** so no metric name means two different numbers depending on which
  semantic view answers (**BREAKING for saved Cortex/BI queries using the old names**):
  - ATTENDANCE `TOTAL_TICKETS_SOLD` → `TOTAL_TICKETS_SCANNED` (scan-side count; DPR keeps
    the canonical Gateway-side `TOTAL_TICKETS_SOLD`).
  - ATTENDANCE `TOTAL_TICKET_REVENUE` → `TOTAL_FORECAST_TICKET_REVENUE` (forecast-side; DPR
    keeps the recognized-actuals name).
  - RETAIL `TOTAL_DONATIONS` → `TOTAL_RETAIL_DONATIONS` (register donations; the name
    UNIFIED already used — DPR keeps all-channel `TOTAL_DONATIONS`).
  - DPR/UNIFIED `MUS_STORE_REV_PER_VISITOR` → `MUS_STORE_PROFIT_PER_VISITOR` (it computes
    from gross profit; the name now says so).
  - `AVG_TICKET_PRICE` authored identically everywhere as
    `SUM(TOTAL_ADMISSION_REVENUE) / NULLIF(SUM(TICKETS_SOLD), 0)`.
  - Consumer updated: `rpt_daily_scan_powerbi` (output alias unchanged — Power BI unaffected).
- **One deployment method** — `scripts/generate_semantic_view_ddl.py` renders deploy DDL for
  every `cortex_project/*.sv.yaml` (the single authored source of truth) with a `--check`
  drift mode; `.githooks/pre-commit` rewritten to enforce it (the old hook pointed at the
  deleted `semantic_models/` paths and could never fire). Regenerated attendance/retail DDL;
  generated the previously missing DPR/UNIFIED DDL.
- **`JMYERS_TEST.agent.yaml` → `DPR_ANALYST.agent.yaml`** — team-owned agent, deployed as
  `NS11MM_DW_DEV.MARTS.DPR_ANALYST`.

## Fixed

- ATTENDANCE/RETAIL seed references pointed at schema `MARTS`; seeds build to `SEEDS`.
- **Fiscal-calendar claims scrubbed** (dim_date has no fiscal columns): descriptions, the
  phantom `fiscal_year`/`fiscal_month` schema.yml columns on `rpt_dpr_powerbi`, and the
  YTD/monthly report headers now say calendar-based, with the fiscal variant deferred to the
  Data & AI Committee under ADR-005 (proposed FY start: October).

## Removed

- `FUNDRAISING_ECOM.sv.yaml` → `cortex_project/disabled/` and out of the deploy manifest —
  all four of its base tables are disabled dims; it cannot deploy.

---
