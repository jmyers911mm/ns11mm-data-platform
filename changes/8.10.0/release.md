# 8.10.0: Retail Analysis Report

- **Date:** 2026-08-12
- **Version:** 8.10.0

Migrates the last uncovered live retail workbook and, more importantly, builds the
`fact_retail_analysis` equivalent that **six other live surfaces already read** — the brief
named four. Not gated: every number this release publishes is new and nothing that exists
today moves. It also discharges one line item of the cross-release integration pass.

## Added

- **`int_retail__analysis`** — facility-day components, no quotients. Reproduces the legacy
  carve-outs on the item **description**, not on `item_no`: `key_item_descr` is a surrogate
  over `IM_ITEM.DESCR` (proved by `t_dim_item_desc_from_ecommerce`, which loads the same
  dimension from Drupal `uc_order_products.title`, a source with no item number at all), so
  two SKUs sharing a description share one key and legacy excludes both.
- **`fct_retail_analysis`** — the `fact_retail_analysis` equivalent at facility-day grain.
  Every one of the six legacy readers consumes it as `SUM(<area>_<measure>)` over a date
  range at day grain and none of them joins it to anything, which is what makes the long
  grain safe. `museum_attendance` / `memorial_attendance` are day-level and repeated on every
  facility row — summing them across facilities multiplies them by the facility count, which
  is the one footgun the grain introduces and is called out in the fact header, the column
  doc and the serving model.
- **`rpt_retail_analysis_report_long`**, **`..._narrative_brief`**, **`..._narrative`**
  (`enabled=false`), **`dim_retail_analysis_line_item`**, **`retail_analysis_line_items`
  seed** (32 lines, 6 sections). No `*_powerbi` wrapper — no `RETAIL_ANALYSIS` semantic view
  is added, and a wrapper over nothing is an ADR-021 violation rather than a convenience.
- **`seed_retail_analysis_excluded_item`** — `key_item_descr` `2449`–`2454` **resolved** to
  `item_no` `100564`–`100569`, and not by guesswork: `t_fact_mus_store_analysis` carves
  exactly those six keys *in* at facility 1080 as the membership lines, and
  `t_fact_num_tickets` defines the same 1080 cohort as store-14 documents containing exactly
  those six item numbers. Six items, one facility, one product family, stated twice under two
  different keys.
- **`seed_retail_water_item`** — the `4636` and `5095` water keys, `is_resolved = FALSE`.
- **Four tests**, including `assert_retail_analysis_sales_within_retail_daily` (error), which
  asserts the deliberate inequality between this family's sales and `fct_retail_daily`'s
  holds in the correct direction on every build.
- **`dbt_project.yml` version 8.9.0 → 8.10.0.**

## Changed

- **`seeds/_seeds.yml` is now a genuinely cumulative merge — 34 blocks, YAML-validated.**
  8.4.0, 8.5.0 and 8.6.0 each edited this file from the 7.13.0 baseline rather than from each
  other, so 8.6.0's copy silently reverted 8.2.0's expanded scope/exclusion/donation docs
  **and dropped `seed_sensource_facility_map` and `seed_carts_denominator_rule` entirely**.
  The copy here takes, per seed block, the latest release that actually changed it.
- **`models/intermediate/schema.yml` and `models/marts/facts/schema.yml`** are cumulative the
  same way: 8.8.0 shipped full-file copies, 8.9.0 shipped fragments. These are full files
  carrying both plus the two new blocks, so whoever applies the series does not have to
  reconcile two conventions. Documentation only — no SQL, no measure.

## Why a new `retail_analysis/` family rather than more models in `retail/`

Four grounds, the fourth decisive. It is a separate live artefact with its own transformation
and recipient list; its printed surface is disjoint (Preview Site / Vesey and E-Commerce here,
Museum Cafe and MUS AG there); its budget vocabulary differs (E-Commerce goals come from
`fct_budget_dpr_forecasts`, not `fct_budget_retail_forecasts`); and **the same-named measures
are different numbers**. Every Retail Analysis sales branch carries
`key_summary_category <> '6' AND key_item_descr NOT IN ('2449'..'2454')`; the Retail
Performance chain applies no item exclusion. `MS__SALES` and
`MUSEUM_STORE__GROSS_MERCH_SALES` are both correct for the same facility-day and are not
equal. One layout catalog would put two definitions of "Museum Store sales" one row apart
with no way for a reader to see why they disagree.

The thirteen legacy sheets are **years 2014–2026**, routed from one query by a `SwitchCase` on
`year(key_date)` and growing by one every January. They are a `dim_date` slicer, not layout.

## Findings recorded in the caveats tables (no code change this release)

- **BLOCKER: the water carve-out key `4636` cannot be resolved from any staged source**, and
  nothing in the 216 captured transformations carves it in by another key, so there is no
  second statement to triangulate against. `water_sales`, `water_cost` and
  `water_gross_profit` are typed NULL (cause: *blocked on a business rule*) and
  `WATER__MUS_STORE` / `WATER__MEM_CART` are `Stub`. Note also that Retail Performance defines
  water as `('4636','5095')` — **two** keys — while the Retail Analysis carve-out uses one;
  whether that is deliberate is part of the same question. The resolution query is NOTES §7.1
  and **must run before the legacy MySQL estate is decommissioned**;
  `assert_retail_analysis_carve_out_keys_unresolved` keeps it visible in every build and goes
  silent by itself once the seed is filled.
- **`911dw.medallion_machine` has no writer among the 216 captured transformations** and no
  staged equivalent — the same class of gap as memorial attendance. It is read by two live
  surfaces, so **Tracker-YTD is understating its cafe line by the medallion profit** until
  this is sourced. Three layout lines are `Stub`.
- **The legacy sales/cost asymmetry is reproduced, not fixed.** The membership exclusion is
  applied to sales (`t_fact_retail`, all branches) and not to cost (`t_fact_cogs` has no
  category or item filter), so `profit_mus_store` is sales-excluding-memberships less
  cost-including-memberships. That is what the certified series has always computed;
  correcting it moves a decade-old published number.
- **`int_dpr__retail` still applies no item exclusion at all**, so the live DPR's Museum Store
  and Memorial Carts gross profit include membership sales and legacy's do not
  (`t_reporting_mus_store_profit` and `t_reporting_mem_cart_profit` both carry
  `key_item_descr not in ('2449'..'2454')`). The new seed makes the fix two lines, but it
  moves a certified number and belongs in its own ADR-005 release. Same argument, same owner
  for `retail/`'s `MUSEUM_STORE__GROSS_MERCH_SALES`. *Owner: Gennady Zaritsky.*
- **Observed while rebasing, for the integration pass: 8.6.0's `int_dpr__retail.sql` still
  costs with `sale_cost`** — it was written from the 7.13.0 baseline and does not carry
  8.3.0's `net_cost` netting fix. Same class of non-cumulative divergence as the `_seeds.yml`
  one fixed here.
- **`MEM_CART__CAPTURE_RATE` is published here and the same shape is withheld in `retail/`.**
  8.5.0 left `MEMORIAL_CARTS__CONVERSION_RATE` `Stub` rather than pick a name for the
  committee; this release publishes the shape under the legacy column's own name
  (`mem_cart_capture_rate`) on a report where the name is not in dispute. If the committee
  would rather withhold both, it is one cell in `retail_analysis_line_items.csv` and no SQL.
- **The memorial-attendance facility set still disagrees with itself.**
  `t_fact_mus_store_analysis` reads it at `(1000, 2000)`; `t_fact_attendance_all_locations`
  at `(2000)`. 8.4.0 encoded `2000`; this release consumes the same measure for a line whose
  legacy source is the `(1000, 2000)` form. *ADR-005, owner: Chris Wogas.*
- **Legacy aliases two different measures to the same output name** inside one `UNION` branch
  of `t_fact_mus_store_analysis` (`musag_units_sold` shares an alias with `mtg_units_sold` at
  1070 and with `mus_memberships_units_sold` at 1080). This release does not reproduce the
  entanglement, so a legacy-vs-dbt unit diff there is not necessarily a migration bug.
