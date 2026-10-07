# 7.9.0: Fact-Layer Correctness

- **Date:** 2026-07-31
- **Version:** 7.9.0

Fixes the two numbers-level defects found by the post-build review (retail return
netting, retail budget grain), hardens the Daily Scan lineage against fan-out, and
closes the test-coverage gaps against the severity rule.

## Fixed

- **Retail return netting centralized — one convention, authored once.**
  `int_retail__performance` netted returns as `sale_amount - return_amount` while every
  other consumer of the same lines (all five DPR selling-area measures,
  `fct_daily_operations.retail_revenue`, and its own donations measure) nets with `+` —
  the legacy-reconciled convention, implying returns land with negative amounts. One of
  the two is wrong for any day with a return; the `-` form overstates the Retail
  Performance chain by 2× returns. Fix: `int_counterpoint__retail_lines` now derives
  **`net_amount` / `net_quantity` once** (with the sign convention documented in-model);
  `int_retail__performance` (bug fix), `int_dpr__retail` and `fct_daily_operations`
  (output-equivalent refactors) all consume the shared columns.
  **CONFIRM with a CounterPoint 'R'-line extract (owner: Gennady)** — if returns land
  positive, the sign flips in ONE place.
  Verify: `dbt build --select int_counterpoint__retail_lines+` — `int_dpr__retail` /
  `fct_daily_operations` outputs must be row-identical pre/post; `fct_retail_performance`
  changes ONLY on days with returns.
- **New cross-chain reconciliation test**
  `assert_retail_dpr_cross_chain_reconciliation` (warn — promote after a clean run):
  day-level Museum Store net sales must tie between the Retail Performance chain and the
  DPR chain within 0.5% over the trailing 30 days, so the two lineages can never diverge
  silently again.
- **Retail budget grain corrected — category seam is NULL by design.**
  `fct_retail_performance` joined the facility-grain forecast onto
  date×facility×**category** rows, repeating the facility budget on every category row —
  any category rollup multiplied the budget (and contradicted the build spec §8.6 and
  `rpt_retail_category_long`'s own header). The category-grain budget columns are now
  typed NULLs; **the single budget surface is `fct_budget_retail_forecasts` →
  `rpt_retail_budget_daily`** (one budget, one chain).
- **Duplicate retail-budget landing retired**: `stg_budget__retail` deleted (its only
  consumer was the seam above); `report_estate_seed.seed_retail_budget` deregistered
  from sources.yml with a retirement note — it was a second landing of the same
  workbook as `budget_seeds.SEED_RETAIL_FORECASTS` (the canonical source). The RAW
  table may remain; it is deliberately unread.
- **Daily Scan fan-out guard**: `int_gateway__scan_lines`' ticket join deduped to one
  row per `visual_id` (latest journal line) — `stg_gateway__jnltickets` is
  jnl_detail_id-grain, so a reissued/adjusted ticket duplicated scan rows and inflated
  `passes_scanned` / `tickets_sold` in `fct_daily_scan`.
- `fct_daily_scan`: redundant mart-layer `try_to_decimal` re-guards removed (guards
  live upstream per the DQ rule); the intentional exclusion of the staged `mobile` /
  `partners` budget columns from the segment unpivot is now documented in-model
  (13 segments, matching the legacy report).

## Added — test coverage per the severity rule

- GROUP-BY-enforced grains at **error**: `rpt_monthly_retail_kpi`
  (calendar_year × calendar_month × key_facility), `rpt_website_commerce`
  (month_of_year × revenue_type × revenue_year).
- Inherited/asserted grains at **warn**: `rpt_retail_powerbi` (report_date ×
  key_facility — matches the DPR sibling), `fct_ticket_demand_forecast` (declared
  5-column grain asserted under the 14-column GROUP BY),
  `int_gateway__scan_lines.usage_id` (unique), and
  `int_gateway__item_journal_lines.jnl_detail_id` (unique — same fan-out exposure that
  motivated the ticket-side test).
- Severities aligned **down** where grains are inherited from the Excel budget seeds:
  `fct_budget_dpr_forecasts.date_key` unique and both `fct_budget_*_grain_unique`
  combos error → warn, matching their deliberately-warn `int_budget__*` twins.

## Migration notes

1. `dbt build --select int_counterpoint__retail_lines+` and row-count/row-diff the DPR
   chain (must be identical) and `fct_retail_performance` (changes only where returns
   exist). Reconcile a recent day against the legacy Retail Performance PDF.
2. Re-deploy the RETAIL semantic view (budget fact descriptions updated).
3. Anything that read `fct_retail_performance.net_sales_budget/net_profit_budget`
   should rebind to `rpt_retail_budget_daily`.

---
