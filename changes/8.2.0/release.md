# 8.2.0: Retail Scope (many-to-many store→facility)

- **Date:** 2026-08-12
- **Version:** 8.2.0

Rebuilds the CounterPoint retail scope so it expresses what legacy `t_fact_retail` actually
does: **seven independent store queries**, a **many-to-many, date-bounded** store→facility
relationship, and **per-query** item carve-ins, carve-outs, zero-pricing and donation
reclassing. Nothing here changes cost or the netting convention — that is 8.3.0.

## Added

- **`seed_retail_store_scope` replaced.** Was a nine-row `store_id` in-scope list. It is now
  one row per legacy query × store, carrying the date window, item carve-in/carve-out, the
  shipping filter, the override flag, the price column and an `is_primary_facility` flag.
- **`seed_facility_area` gains 1001 Preview/Vesey and 1002 Visitors Center.** Not on the
  original deliverable list but required: this is the first release in which those two
  facilities carry data, and without seed rows they render as `Unmapped 1001` / `Unmapped
  1002` in `dim_facility`, `fct_retail_performance` and `fct_retail_daily`.
- **`assert_retail_scope_seed_covers_legacy_stores`** — plus column docs and tests for all
  five changed seeds in `seeds/_seeds.yml`.
- **`dbt_project.yml` version 8.1.0 → 8.2.0.**

## Changed

- **`int_counterpoint__retail_lines`** rewritten to fan out over the scope seed.
- **`seed_retail_item_facility`** gains `store_id_scope` and `valid_from`; the grain is now
  `item_no + store_id_scope` (15 rows, was 10). **`seed_retail_zero_price_item`** gains
  `key_facility_scope`; grain `item_no + key_facility_scope` (5 rows, was 2).
  **`seed_retail_donation_item`** gains `store_id_scope`, `reclass_to_donation` and the
  `7-00003` → `ecom_ask` row.
- **`fct_daily_operations` gains `where r.is_primary_facility` on its retail CTE.** This is
  the integration change the fan-out forces. Every consumer that groups by `key_facility` —
  `int_retail__performance`, `fct_retail_performance`, `fct_retail_daily`, `int_dpr__retail` —
  is unaffected and now more correct, but `fct_daily_operations.retail_revenue` and
  `.retail_transactions` sum the line model with **no facility grouping** and would
  double-count stores 1, 8 and 10 at day grain, flowing into `total_revenue`,
  `retail_revenue_per_visitor` and `ml_visitor_forecast_training`. `is_primary_facility` is
  TRUE on exactly one scope row per source line. Without the filter, `retail_revenue`
  overstates by the full store-1/8/10 contribution.
- **`seed_retail_excluded_item` is left on disk but is now referenced by nothing.** Its only
  row (`201205`) was a Sales-4-scoped exclusion the old model applied globally. Delete it in a
  follow-up once 8.2.0 has shipped clean.

## Numbers that move

- **Stores 2, 4, 5, 6 and 7 enter the platform for the first time — total retail revenue rises
  by the whole history of five stores.** Legacy Sales 1 (stores 2, 5, 7 → 1002) and Sales 2
  (stores 1, 4, 6, 8 → 1001) were entirely absent from the old scope seed. Two new facilities
  appear in `fct_retail_performance` and `fct_retail_daily`. This is the largest single
  increase in the release; size it before shipping.
- **Stores 1, 8 and 10 now produce two rows per line**, because legacy deliberately reports
  the same line under two facilities (8 under 1003 and 1001; 10 under 1003 and 1030 from
  2019-12-10; 1 under 1001 and 4007 from 2022-11-28).
- **Zero-pricing is no longer global — `net_sales` rises at 1234 and 4007.** The old model
  zero-rated `200933` and `201229` everywhere; legacy zeroes them only at 1003 and 1020, store
  1 zeroes `200933` only, and store 3 zeroes nothing. Ecommerce sales of either SKU and cafe
  sales of `201229` were being booked at $0. No change at 1003 or 1020.
- **The Sales-4 item carve-outs are now store- and date-scoped — 1040, 1060, 1070 and 1080
  lose all pre-cutover and out-of-cohort rows, and 1020 Memorial Carts gains them.** This
  moves `mag_cp_revenue`, `musag_profit` and `musag_units` in `int_dpr__retail`, and therefore
  `audio_tour_headset`.
- **Item 201205 stops being deleted — 1003 Museum Store rises slightly.** Legacy carves it
  *in* to 1003 from store 14 and only excludes it from Sales 4; the old global exclusion
  silently deleted that carve-in.
- **Item 7-00003 is reclassed to Donations at store 3 — 1234 merchandise falls and
  `ecom_donation_ask` rises by the same amount.**
- **1002 only:** Sales 1 is the only legacy query summing `GROSS_EXT_PRC` rather than
  `EXT_PRC`, and the only one with no `DESCR not like '%shipping%'` filter. Both are now
  per-query. Since 1002 is new here there is no before/after to compare.

## Findings recorded in the caveats tables (no code change this release)

- **SCOPE NOTE — three legacy ambiguities are resolved in favour of the dated behaviour, and
  each changes what a certified metric counts.** Recorded rather than gated, but they need
  sign-off. *Owner: Gennady Zaritsky.*
  1. **Sales-4 carve-out cutovers.** `t_fact_retail` applies the item CASE with no date bound;
     `t_fact_cogs` gates each cohort (1040 from 2023-09-04, 1060 from 2024-01-16, 1070/1080
     from 2024-01-21) *and* excludes those items from 1020 entirely. The two legacy
     transformations disagree. Implemented: the cogs cutovers, with pre-cutover lines falling
     back to 1020.
  2. **Store 1 → 4007 start date.** `t_fact_retail` Sales 7 has no date bound; `t_fact_cogs`,
     `t_fact_num_tickets` and `t_reporting_donations` all gate at 2022-11-28. Implemented:
     dated.
  3. **Price column.** `net_amount` follows `t_fact_retail` because the certified Retail
     Performance series descends from `fact_retail` — but `t_fact_cogs` uses `GROSS_EXT_PRC`
     throughout, **so the DPR gross-profit sales side is arguably on the wrong column today.**
- **Legacy return quantity is `SUM(LINE.QTY_SOLD)` on `'R'` lines, not `QTY_RET`.** The model
  keeps the platform convention (`quantity_returned`). If CounterPoint populates the two
  differently on returns, `net_quantity` will diverge from legacy `Return_QTY`.
- **`t_fact_cogs` sums `GROSS_EXT_PRC` in every branch while `t_fact_retail` does not**, so
  the cost chain and the sales chain disagree about the sales side in legacy itself.
