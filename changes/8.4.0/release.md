# 8.4.0: Sensource Visitor Crosswalk

- **Date:** 2026-08-12
- **Version:** 8.4.0

Fixes a dead join that made every Sensource-derived number on four live reports permanently
zero. Not gated: no metric definition changes — measures that were unreachable become
reachable. The definitional questions this release surfaces are all deferred to 8.5.0 under
ADR-005.

`int_retail__visitors` passed the Sensource **sensor** `key_facility` straight through, and
`fct_retail_daily` joined it to the **reporting** facility key. Sensource numbers its sensors
`1000–1009`; the reporting keys come from `seed_facility_area` (`1003, 1020, 1030, 1234,
4007, 1040, 1060, 1070, 1080`). The two vocabularies overlap on exactly one value — `1003` —
and that overlap is a false friend: Sensource 1003 is a sensor, reporting 1003 is the Museum
Store, and the Museum Store's sensor is **1007**. So the join matched nothing that meant
anything, and `visitor_count` was `coalesce(..., 0)` = 0 forever, **whether or not the feed
landed**. The feed did land (1.6.2), which means the platform has been reporting zeros over
live data since July.

## Added

- **`seed_sensource_facility_map`** — five rows, one per verified legacy mapping, each citing
  the file and line it came from: 1007 → 1003 (`num_entry`), 1001 → 1001 (`num_exit`),
  1006 → 1030 (`passes_scanned`), 3000 → 1030 (`passes_scanned`), 2000 → 2000
  (`passes_scanned`). **The entry-vs-exit split is real and load-bearing** — the Museum
  Store's main door counts entries and Vesey's count is taken on exit. `num_exit` was staged
  in 1.6.2 and read by nothing until now.
- **`int_attendance__sensource`** — pivots the crosswalked counts into the five named areas
  the Attendance Report prints, including `memorial_only = memorial_attendance −
  museum_attendance` exactly as legacy computes it. It reads `int_retail__visitors` rather
  than re-resolving the crosswalk, so the sensor → reporting pivot is authored once.
- **`assert_sensource_facilities_resolve`** (warn) — raises any sensor facility present in the
  staged feed with no crosswalk row, returning the row count and unmapped measure totals so
  the size of the gap is visible.
- **`dbt_project.yml` version 8.3.0 → 8.4.0.**

## Changed

- **`int_retail__visitors`** inner-joins the crosswalk, selects the seeded measure column per
  facility, and emits `reporting_facility` as `key_facility`. The Shopify leg is unchanged;
  the blanket "STUB STATUS" header is replaced with a `STATUS:` line that is accurate per leg.
- **`fct_retail_daily`** — the facility-day spine becomes `perf UNION (visitors ∩
  dim_facility)`. The intersection is deliberate: it lets the Atrium (1030) — a visitor-only
  area with no CounterPoint sales, whose rows the category-fact spine dropped before they
  reached `rpt_retail_carts_analysis` — through, while keeping attendance-only facilities
  (Vesey 1001, Memorial Plaza 2000) out of the retail fact where they would surface as
  `Unmapped` rows with zero sales.
- **`rpt_attendance`** repointed from `stg_sensource__attendance` — a pre-pivoted landing
  table with no facility crosswalk and no legacy provenance — to `int_attendance__sensource`.
  Side effect: this removes a staging read from the marts layer, which was a layering
  violation.
- **Six availability flips across three layout seeds**: `MEMORIAL_ONLY`, `MUSEUM_STORE` and
  `MUSEUM_STORE_VESEY` on the Attendance Report (the whole report is now `Available`),
  `MUS_VISITORS` on the carts report, and `MUSEUM_STORE__VISITORS` plus
  `MUSEUM_STORE__CONVERSION_RATE` on Retail Performance. `today_sales_line_items.csv` ships
  **unchanged, deliberately**, so the release diff shows it was considered.

## Numbers that move

- **`visitor_count` goes from 0 to real** at 1003 (`num_entry` at sensor 1007) and 1030
  (scanned passes at 1006+3000). The verification query that returns zero rows before this
  release returns rows after it.
- **Six line items go from blank to populated**, listed above. Museum-store conversion should
  land roughly 0.25–0.45; a value above 1 means the entry/exit column choice is inverted for
  1007, and a value near 0.01 means the denominator is picking up museum attendance instead of
  store entries.
- **No additive total in `fct_retail_daily` moves.** The spine union only adds rows whose sales
  side is NULL → 0; `net_sales`, `net_profit`, `donations` and `transactions` must be
  identical before and after.

## Findings recorded in the caveats tables (no code change this release)

- **Sensor 3000 and facility 2000 have no writer in the captured Pentaho set.**
  `t_fact_museum_passes_scanned` writes only 1006 and 5000; nothing in the 216 captured
  transformations writes 3000, and **nothing writes `911dw.memorial_attendance` at all**. Both
  are read by five live reports. Either the writers are among the seven transformations
  missing from the capture, or these are historical facilities no longer fed. Needs
  confirmation before the Pentaho server is decommissioned.
- **The memorial attendance facility set is inconsistent in legacy** — `in (2000)` in one
  family, `IN (1000, 2000)` in another. `2000` is encoded here per the Attendance Report's own
  ground truth. If 1000 carries non-zero passes the two families disagree today and always
  have. *ADR-005, owner: Chris Wogas.*
- **Memorial Only will not tie to printed Memorial − Museum.** The printed lines are DPR scan
  measures; Memorial Only is the Sensource pair, per legacy. Both are legacy-faithful and they
  do not reconcile. Flagged as a `SCOPE NOTE:` on both affected models.
- **`stg_sensource__attendance` now has no reader.** Left in place rather than deleted — it is
  a useful independent reconciliation source for exactly the three lines this release derives,
  and worth an explicit parity check before it is retired.
- **`MEM_VISITORS` is deliberately not flipped.** It reads `visitor_count` at facility 1020,
  where no Sensource sensor maps and none should; legacy's `mem_visitors` is memorial
  *attendance*. Re-pointing it changes what a printed denominator counts, so it and everything
  downstream of it (`MEM_VISITORS_LESS_25`, `ADJ_VISITORS`, `CAPTURE_RATE`, `PROFIT_PER_CAP`,
  `SALES_PER_CAP`) stay `Stub` for one release. Same reasoning for
  `MUSEUM_STORE__CAPTURE_RATE`: publishing a number and restating it one release later is more
  expensive than leaving it blank.
- **Today's Sales gets zero flips because it is a feed gap, not a mapping gap.** That report is
  hourly; `stg_sensource__visitors` is daily, and the legacy hourly chain is not staged.
- **`seed_facility_area` has no row for 1001 (Vesey) or 2000 (Memorial Plaza)**; the fact spine
  is written to exclude them, so nothing is broken. Vesey has legacy retail sales at
  `key_facility = 1001`, so surfacing it later is a separate change with semantic-view
  consequences.
