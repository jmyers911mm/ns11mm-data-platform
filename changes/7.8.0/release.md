# 7.8.0: Semantic Layer: Metric Truth

- **Date:** 2026-07-31
- **Version:** 7.8.0

Closes the metric-definition drift found by the 2026-07-31 post-build review: the DPR
DDL was stale (missing the two ratio metrics — `--check` failed), and the ratios
themselves violated the 2026-07-29 locked definitions.

## Fixed

- **`AVG_TICKET_PRICE` (DPR.sv.yaml) now matches the locked canon**:
  `SUM(TOTAL_ADMISSION_REVENUE) / NULLIF(SUM(TICKETS_SOLD), 0)`. The prior
  metric-on-metric form (`TOTAL_ADMISSION_REVENUE / TICKETS_SOLD`) had no NULLIF
  (divide-by-zero on closed days) and an unaggregated denominator (undeployable as a
  semantic-view metric — the likely reason the committed DDL had been hand-pruned to 47
  of 49 metrics).
- **`MUS_STORE_PROFIT_PER_VISITOR` (DPR.sv.yaml)** adopts UNIFIED's correct
  `SUM(...) / NULLIF(SUM(...), 0)` form — one locked name, one formula everywhere.
- **`TOTAL_ADMISSION_REVENUE` single-sourced** — DPR and UNIFIED both summed
  `TICKET_REVENUE + PASS_REVENUE`, re-deriving the governed numerator the fct defines
  once. Both now `SUM(TOTAL_ADMISSION_REVENUE)` (the "view re-chooses a component"
  anti-pattern, removed).
- **`TOTAL_RETAIL_DONATIONS` deduplicated in RETAIL.sv.yaml** — the facility-grain
  rollup silently reused the locked category-grain name. Renamed
  `TOTAL_RETAIL_DONATION_ASK` (namespacing note corrected);
  `rpt_retail_powerbi` updated to the new metric name (its output alias `donations` is
  unchanged, so report_long / narrative consumers are unaffected).
- **`ATTENDANCE.sv.yaml` FCT_DAILY_SCAN primary key** corrected `(DATE_KEY)` →
  `(DATE_KEY, SEGMENT_KEY)` — the declared PK understated the fact's true grain
  (UNIFIED already had it right).
- **All four deploy DDLs regenerated; `generate_semantic_view_ddl.py --check` is green.**
  MARTS.DPR now deploys all 49 metrics. The pre-commit sv-drift hook stops blocking.
- **`rpt_daily_performance_report`** ratio block aligned with the semantic view:
  `mus_store_rev_per_visitor` → **`mus_store_profit_per_visitor`** (it computes from
  gross profit; name now says so — DPR_LINEAGE updated), and zero-denominator handling
  changed from `0` to `NULL` (`nullif`) so the two surfaces agree on zero-sales days.
  **Breaking** for anything bound to the old column name or relying on 0-not-NULL.

## Changed

- `DPR.sv.yaml` `TOTAL_RETAIL_GROSS_PROFIT` description now warns that the metric
  (store + carts + cafe) is NOT the legacy DPR report's "Total Retail Gross Profit"
  line (store + carts + e-commerce, cafe separate). Component realignment or rename is
  an **open ADR-005 item** for the committee — flagged, not changed, because the
  `TOTAL_RETAIL_GROSS_PROFIT` metric code flows through `rpt_dpr_report_long` and the
  line-item seed.
- `scripts/generate_semantic_view_ddl.py` — stray AI-attribution comment removed
  (banned by the header standard).

## Migration notes

1. Re-deploy the four semantic views (`scripts/deploy_semantic_view_*.sql` after
   `USE DATABASE <target>`, or via the cortex manifest).
2. Saved Cortex/BI queries using the RETAIL facility-grain `TOTAL_RETAIL_DONATIONS`
   must switch to `TOTAL_RETAIL_DONATION_ASK` (the category-grain locked name is
   unchanged).
3. Anything reading `rpt_daily_performance_report.mus_store_rev_per_visitor` must
   rebind to `mus_store_profit_per_visitor`.

---
