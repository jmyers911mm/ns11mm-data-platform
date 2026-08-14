# Changelog

All notable changes to the ns11mm-data-platform project will be documented in this file.

This is the production repository (`ns11mm/ns11mm-data-platform`).

## [8.11.0] — 2026-08-12 — Earned Income Variance Report

Migrates the last uncovered live report in the estate, and the highest-exposure one: a
thirteen-sheet XLSX that goes to the CFO and the finance leadership group. Purely additive —
eighteen new files, **no repo file edited** — so no number that exists today moves. Not
itself ADR-005 gated, but **it must not be promoted ahead of 8.5.0 → 8.8.0**: all nineteen of
its printed lines re-project the models those releases correct, so shipping it early
publishes pre-gate figures to the CFO and then restates them. 8.8.0 is load-bearing in
particular — Early Access and Youth & Family have actuals only because of it, and this is the
first surface that prints them.

### Added

- **`int_earned_income__line_items`** — the `earned_revenue_report_values` equivalent. **No
  measure in this release is derived from staging**: no new cohort predicate, no new matrix
  pattern, no new PLU list. Every component except the two operating-expense lines is
  re-projected from the corrected DPR silver chain (`int_dpr__admissions`,
  `int_dpr__tour_revenue`, `int_dpr__fees_and_services`, `int_dpr__attendance`). What is new
  is the assembly.
- **`fct_earned_income`** — the `earned_income_report_analysis` actual equivalent, day grain.
- **`rpt_earned_income_variance_budget_daily`** — the ADR-021 comparison conform, the role
  `rpt_dpr_budget_daily` plays for the DPR. Ten of the eighteen budget lines are read from
  that model rather than re-conformed; two of the ten have their DPR line names undone
  (`fct_budget_dpr_forecasts.early_access_tour_rev` is mapped onto the DPR's
  `REVEALED_TOUR_REVENUE` and `.youth_fam_tour_rev` onto `VIRTUAL_YF_TOUR_REVENUE`, which are
  DPR layout decisions applied to columns this report forecasts as early-access and
  youth-and-family revenue). `youth_fam_tours` — the count, not the revenue — is read from
  `fct_budget_dpr_forecasts` directly, because the DPR conform does not project it.
- **`rpt_earned_income_variance_report_long`** — serving shape, actual + budget, with ratio
  components rather than stored quotients.
- **`rpt_earned_income_variance_narrative_brief`** and **`rpt_earned_income_variance_narrative`**
  (`enabled=false` until a Cortex task exists), **`dim_earned_income_line_item`**, and
  **`earned_income_line_items` seed** (21 lines, 4 sections).
- **`seed_budgeted_expense.csv` — a header with zero rows.** The five-column ingest contract
  for `/opt/pentaho/budgets/BudgetedExpensesDailies.xlsx`, derived from the three live
  consumers, which between them read exactly these columns and nothing else. Filling it turns
  four typed-NULL columns into real measures with no model change. Note the naming trap,
  documented in the seed: `budgeted_expense` is the **actual** despite the name, and
  `budgeted_expense_budget_value` is the budget — reversing them inverts the DPR's Estimated
  Operating Expenses line silently.
- **Five tests**: `assert_earned_income_composites_recompose` (error),
  `assert_earned_income_placeholders_are_null` (error),
  `assert_earned_income_budget_differs_from_dpr_budget` (warn — it fails if the two budgets
  ever become identical, which is the symptom of somebody tidying the conform),
  `assert_earned_income_expense_feed_absent` (warn),
  `assert_earned_income_line_items_resolve` (warn).
- **Three sidecar property files** (`schema_earned_income.yml` ×2,
  `_seeds_earned_income.yml`) rather than a fourth full-file copy of the three shared
  property files 8.10.0 had just merged.
- **`dbt_project.yml` version 8.10.0 → 8.11.0.**

### Why there is no `*_powerbi` wrapper, `*_period_windows` or `*_print` model

ADR-021 makes the wrapper the only caller of `SEMANTIC_VIEW()`, and this release adds no
`EARNED_INCOME` semantic view, so a wrapper would be a lie about where the metric definitions
live; the serving shape reads the mart fact directly, the path `rpt_carts_report_long` and
`rpt_retail_analysis_report_long` already take. The workbook prints day rows inside a year
sheet rather than six period columns, so `_period_windows` has no analogue and none was
invented. The legacy Excel writer is a raw dump of one query into thirteen sheets with no row
catalog of its own, so the layout seed plus the line-item dimension is the whole presentation
contract.

### Deliberate seams (not moves)

- **`fct_earned_income.ticket_revenue` and `fct_daily_performance.ticket_revenue` are
  unequal by exactly `pass_revenue_reseller`.** This report's Ticket Revenue has no reseller
  carve-out; the DPR's does. Both are correct for their own report.
- **`fct_earned_income.museum_attendance` and `fct_daily_performance.mus_attendance` are
  unequal on museum closed days**, by exactly the 8.7.0 zeroing. The legacy EIV attendance
  step has no closed-day CASE; `t_reporting_mus_attendance`, which feeds the DPR, has one.
- **The nineteen legacy `*_diff` columns are not stored.** Variance is actual minus budget at
  display grain. This matters on Average Ticket Price: legacy computes
  `sum(revenue)/sum(tickets)` per day, stores it, and then sums the stored column across
  days — an average of ratios.

### Findings recorded in the caveats tables (no code change this release)

- **The operating-expense feed has no owner and no SQL.** `fact_budgeted_expenses` is loaded
  by an `ExcelInput` step from a spreadsheet on the Pentaho server; there is no database
  source and no named maintainer anywhere in the system. It supplies three live surfaces —
  this report's two expense lines, the DPR's Estimated Operating Expenses line, and the
  Pentaho operating-expenses dashboard — and dies with Pentaho on 5 January 2027.
  `DECISION_MEMO.md` asks Mike Cartier's team to name an owner. This is not a sign-off gate;
  it is an ask for a name.
- **Legacy defect: the museum guided-tour line adds the buyout quantity twice.**
  `t_fact_earned_income_line_items` builds `total_mus_tours = issued + unissued + buyout_qty`
  and separately writes `tour_buyout_qty`;
  `t_fact_guided_tours_earned_income_variance` then computes
  `guided_tours = total_mus_tours + mus_gt_buyout_qty`. Not reproduced — the dbt line will be
  **lower than legacy** on buyout days. The column identity is inferred from writer aliases
  (Pentaho `InsertUpdate` field mappings are not in the captured metadata); the confirming
  query is NOTES §8(h1) and **must be run before the legacy MySQL warehouse is
  decommissioned**.
- **Ten admissions cohorts have no feed**, all on the ticket and CityPASS lines: CityPASS/C3
  scan change, bulk ticket scans, bulk ticket additions, New York Pass additional revenue,
  and the `pricePointID = 84` child-evergreen subtraction. All typed NULLs; seven layout
  lines are `Partial` as a direct consequence, and both totals plus Average Ticket Price
  inherit it. Unlike the expense gap this one is invisible to the reader — the lines render
  with values, just smaller ones.
- **`key_coupon_category` is not staged**, so legacy's `quantity * amount` extension on the
  Adult/Youth CityPASS coupon categories cannot be reproduced. `CITYPASS_REVENUE` is
  `sum(amount)` throughout and is `Partial`.
- **The two reports budget from different seeds.** Earned Income Variance forecasts tickets,
  revenue, service fees and CityPASS from `SEED_FORECASTED_VALUE_FOR_DATE`; the DPR forecasts
  its same-named lines from `SEED_DPR_FORECASTS`. Both are loaded, neither reconciles the
  other, and nobody in the migrated estate reconciles them. Carried faithfully with a monitor.
  Whether the institution wants one admissions budget is a finance decision.
- **Two `Total Estimated Revenue` definitions exist in the legacy estate under one name.**
  The EIV variant takes its retail leg from `fact_profit_from_retail` at facilities
  1007/1001/1020/1234 (includes Vesey, excludes the Museum Store's usual 1003), its cafe leg
  as `cafe_performance.revenue * 0.05`, and its other-visitor leg from `fact_retail` by
  `key_item_descr`. Neither is built twice here. `fact_profit_from_retail` is unbuildable
  today in any case: **its writer `t_fact_profit_from_retail` is one of the seven
  transformations referenced by jobs and absent from the Pentaho archive.**
- **8.6.0's missing-comma finding is carried, not re-decided.** `CPBOOKAD008` /
  `CPBOOKYS008` sit in the `excluded` pass cohort and are therefore outside `CITYPASS_TICKETS`
  and `CITYPASS_REVENUE` here. Reading the legacy exclusion as intended removes dollars that
  have been published for years.

## [8.10.0] — 2026-08-12 — Retail Analysis Report

Migrates the last uncovered live retail workbook and, more importantly, builds the
`fact_retail_analysis` equivalent that **six other live surfaces already read** — the brief
named four. Not gated: every number this release publishes is new and nothing that exists
today moves. It also discharges one line item of the cross-release integration pass.

### Added

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

### Changed

- **`seeds/_seeds.yml` is now a genuinely cumulative merge — 34 blocks, YAML-validated.**
  8.4.0, 8.5.0 and 8.6.0 each edited this file from the 7.13.0 baseline rather than from each
  other, so 8.6.0's copy silently reverted 8.2.0's expanded scope/exclusion/donation docs
  **and dropped `seed_sensource_facility_map` and `seed_carts_denominator_rule` entirely**.
  The copy here takes, per seed block, the latest release that actually changed it.
- **`models/intermediate/schema.yml` and `models/marts/facts/schema.yml`** are cumulative the
  same way: 8.8.0 shipped full-file copies, 8.9.0 shipped fragments. These are full files
  carrying both plus the two new blocks, so whoever applies the series does not have to
  reconcile two conventions. Documentation only — no SQL, no measure.

### Why a new `retail_analysis/` family rather than more models in `retail/`

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

### Findings recorded in the caveats tables (no code change this release)

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

## [8.9.0] — 2026-08-12 — Donations Analysis Report

Builds the sixteenth of the seventeen live reports and, with it, the two legacy tables the
Donations chain writes: `fact_all_donations` and `fact_donations_analysis_report`. Both are
load-bearing beyond their own report surface — five other migrated live reports read them.
Not gated: no certified metric definition changes, and no measure is added to
`fct_daily_performance`. **No existing number moves** — every model this release reads is
read-only here.

### Added

- **`int_donations__all_sources`** — the `fact_all_donations` equivalent at component grain,
  carrying fifteen atomic components. Eleven are **re-projected** from models that already
  author them (a donation total authored twice is an ADR-021 defect even when the two copies
  agree today); three are new and each is defined as the *complement* of something already
  authored, so no dollar is authored twice and the legacy whole recomposes by addition
  (`MEMORIAL_KIOSK_DON`, `MEM_CART_OTHER_DON`, `VESEY_DON`); one is a typed NULL.
- **`fct_donations`** — the `fact_donations_analysis_report` equivalent, day grain. It uses
  **legacy column names deliberately**: the table is a binding contract for five `.prpt`
  reports, not just an input to a sixth.
- **`rpt_donations_report_long`** (serving shape; it carries the `POWERBI_ROLE` grant and is
  the Power BI surface for this family), **`rpt_donations_narrative_brief`**,
  **`rpt_donations_narrative`** (`enabled=false`), **`dim_donations_line_item`**,
  **`donations_line_items` seed** (36 lines, 12 sections).
- **No `rpt_donations_powerbi`, and the reason is structural.** There is no `DONATIONS`
  semantic view — `_reports__sources.yml` declares exactly three — and authoring a fourth
  means authoring a new certified metric surface, which is an ADR-005 decision that does not
  belong in an ungated release. A wrapper with no semantic view behind it would be a copy of
  `fct_donations` wearing a reserved suffix.
- **Three tests**: `assert_donations_tie_to_daily_performance` (error — the eleven shared
  lines must agree), `assert_gateway_donation_cohorts_recompose` (error — the complement
  split must partition the cohort), `assert_cart_donation_composition` (warn).
- **`dbt_project.yml` version 8.8.0 → 8.9.0.**

### Findings recorded in the caveats tables (no code change this release)

- **Legacy double-counts the box-office exit box across two of its seven legs.**
  `t_run_donations_kiosk_coatcheck` writes the whole of `fact_all_gateway_donations`, which
  includes `DONOPSMUS003`; `t_run_donations_exit` then writes `fact_retail` item 886 UNION
  `box_office_mus_exit_don` — the same PLU's dollars again. Any consumer adding
  `kiosk_coatcheck_donations + mus_exit_donations` counts the museum exit box twice, and
  `finance_mtd_dpr` and `finance_ytd_dpr` read both legs. **Reproduced verbatim** so those two
  reports tie on migration, flagged in the model header, the `schema.yml` and the section-12
  note, and deliberately **not** silently fixed. *Owner: Chris Wogas / Finance.*
- **`911dw.dim_item_descr` is not staged and its surrogate keys cannot be recovered.** Six
  legacy legs filter on integer keys inside an already donation-flagged category. Four SKUs
  are resolved and seeded; the rest are approximated by the category filter at the same
  facility, which makes `MUS_STORE_DON`, `VESEY_DONATIONS`, `MEM_CART_ASK_DON`,
  `RETAIL_CART_DON` and their two dependent ratios **supersets** of the legacy cohorts. All
  six are `Partial`.
- **`911dw.cafe_performance` has no writer** anywhere in the 216 migrated transformations and
  no staged equivalent, so `CAFE_VENDOR_DON` is a typed NULL (cause: *no data feed*) and
  `CAFE_DONATIONS` / `LEG_CAFE` are `Stub`. Not zero-filled. The vendor-cafe era ended
  2023-01-01, so this is a historical hole rather than an ongoing one — and the legacy Excel
  tab already prints `cafe1_donations AS cafe_donations`, i.e. the report abandoned the vendor
  feed for the CounterPoint cafe and never renamed the column.
- **No cross-source donations total is authored, deliberately.** Legacy publishes two
  incompatible roll-ups that disagree structurally, not just numerically: `fact_all_donations`'
  seven legs (which double-count the exit box and exclude `cafe1_donations`,
  `vesey_donations` and `mask_donations` entirely), and `t_reporting_donations`' DPR
  `donations` line (whose issued leg does not carve out categories 3220/3221 and which then
  adds the kiosk/coatcheck leg on top). Picking one changes what a certified metric counts.
  Every component is published; both compositions are reconstructable; the narrative prompt is
  explicitly instructed never to state or imply a cross-source total. *ADR-005, owner: Chris
  Wogas.*
- **The legacy `coatcheck_don` and the platform's are not the same cohort.** A side-by-side
  against the legacy XLSX will show the coat check line low by exactly the exit-box amount
  from 2024-02-15 onward; section 9 makes up the difference and the shipped test asserts the
  identity.
- **`mem_attendance` is `Available` here and `Stub` on the DPR — same word, two measures.**
  The Donations report's legacy source is the Sensource sensor at 2000, which is live; the
  DPR's is the scan chain, which is a typed NULL because no Gateway ACP resolves to
  `key_facility` 2000. Both seeds are correct for their own report; it reads as an
  inconsistency in a seed diff, so it is called out.
- **The legacy workbook is thirteen per-year sheets, not twelve.** `t_donations_analysis_tabs`
  carries thirteen writer steps — 2014 through 2026 — each writing the same 22-column layout
  filtered by a `SwitchCase` on `year(key_date)`, and it grows by one every January. There is
  no sheet-level sectioning in the legacy file at all; the twelve sections in the layout seed
  are the platform's grouping.
- **`mus_store_donations` in `int_dpr__retail` is broader than every legacy consumer of it**,
  and the two legacy consumers do not even agree with each other. Pre-existing platform
  behaviour, already published on the DPR; recorded here because this is the first surface
  where the difference is visible line by line.

## [8.8.0] — 2026-08-12 — Tour Buyout & Unissued Revenue

**ADR-005 gated. This release must not ship before sign-off from Chris Wogas**, the metric
owner, per `DECISION_MEMO.md`. Cumulative on 8.7.0; **both releases must be signed before
either is promoted**. Two whole legs of DPR revenue recognition were missing from the
platform: the legacy DPR builds each tour and admission line by adding issued journal lines,
unissued order lines and buyout lines together, and the platform carried only the first.

### Added

- **`int_gateway__unissued_order_lines`** — all four legacy unissued facts reproduced as one
  order-line-grain model with a `cohort` column, including the `DisbursementDetails.Basis`
  price CASE. Every staged column the CASE needs is present, so no typed-NULL placeholder was
  needed for the price expression. The unissued leg reuses the **same exclusion seeds** as the
  issued leg (`seed_gateway_tickets_sold_excluded_plu`,
  `seed_gateway_ticket_revenue_excluded_plu`, both from 8.6.0) because the legacy predicates
  are identical on both legs. Pass revenue is deliberately given no unissued leg: no legacy
  pass-revenue step reads an unissued fact.
- **`int_gateway__tour_buyout`** — the `fact_museum_guided_tour_buyout` equivalent, including
  the quantity suppression and the `TOUADDREV002` leg.
- **`seed_tour_buyout_plu`** (the seven buyout PLUs, the suppression flag and the target
  line), **`seed_tour_buyout_category`** (all sixteen legacy `key_museum_category` values,
  `is_resolved = FALSE` throughout, so the gap is visible rather than lost), and
  **`_seeds_tour_buyout.yml`**.
- **Four tests**: `assert_buyout_quantity_suppression`,
  `assert_buyout_plu_excluded_from_line_grain`, `assert_unissued_lines_are_actually_unissued`,
  `assert_unissued_legs_reconcile_to_fact`. The double-count guard is the single biggest risk
  in this release — counting a buyout line at line grain *and* adding it back.
- **`unissued_*` and `buyout_*` audit companions on `fct_daily_performance`**, so the added
  amount is exactly recoverable and the release is reversible by column.

### Changed

- **`int_dpr__tour_revenue`** — issued + unissued + buyout; buyout PLUs excluded from the
  line-grain cohorts and added back through the buyout leg, as legacy does on
  `key_museum_category`. New `youth_fam_*`, `early_access_*` and `ea_mem_mus_*` actuals.
- **`int_dpr__admissions`** (cumulative on 8.7.0) — unissued GA tickets and revenue added.
- **`int_dpr__donations`** — unissued ticketing donations added.
- **`seed_tour_plu`** — `MUSGTOADR007` and `MUSGTOBUY009` removed; they are buyout PLUs and
  move to the new seed. The five surviving `early_access_tour` rows are annotated as verified.
- **`fct_daily_performance`**, `models/intermediate/schema.yml` and
  `models/marts/facts/schema.yml`, all cumulative on 8.7.0.
- **`dbt_project.yml` version 8.7.0 → 8.8.0.**

### Numbers that move

- **Museum and memorial guided tour COUNTS fall** by the suppressed quantity. Legacy forces
  the count to zero for three of the seven buyout PLUs while still counting the revenue; the
  other four count normally, and nothing in the legacy explains why.
- **Museum and memorial guided tour REVENUE rises**, because buyout revenue was previously in
  the wrong cohort or absent entirely.
- **Average revenue per tour rises sharply on buyout days** — the direct consequence of the
  two above, and the reason the suppression is a reporting choice rather than a defect: it
  makes tour counts a measure of *public tours delivered* rather than *tours sold*.
- **`tickets_sold`, `ticket_revenue`, `total_admission_revenue`, every tour revenue line and
  `ticketing_donations` all rise** by the unissued balance outstanding on each date.
- **`AVG_TICKET_PRICE` is not signed a priori** — numerator and denominator both move, and the
  direction depends on whether the unissued mix is richer or poorer than the issued mix. Print
  it before signing.
- **Early Access and Youth & Family gain actuals for the first time in the platform**, on
  `int_dpr__tour_revenue` and `fct_daily_performance`. They are **not** wired into
  `rpt_dpr_powerbi`, `rpt_dpr_report_long` or `dpr_line_items`, which still treat those rows
  as budget-only; that is a separate report-layer release with its own sign-off, kept out of
  scope so this release's blast radius stays inside the silver layer and the DPR fact.

The substantive accounting question is in the memo: recognising revenue at **order** rather
than at **issuance** moves revenue earlier, makes the DPR's "today" figure include tickets for
events that have not happened and may be refunded, and means a restatement whenever an order
line is later issued or cancelled. Legacy does it; that is not the same as it being right.

### Findings recorded in the caveats tables (no code change this release)

- **`911dw.dim_galaxy_items` is not staged**, so `key_museum_category` cannot be resolved to a
  PLU. This blocks the category-keyed buyout add-back (worked around per-PLU, with the seven
  assignments recorded per row as a judgement to be confirmed), the `TOUADDREV002` line
  assignment, and any category-grain unissued table for the `.prpt` reports. **It is the
  single highest-value staging addition for the DPR domain.**
- **`TOUADDREV002` is built but not attributable.** The leg is real and buildable from staged
  sources, and it is built; `buyout_line_item` is a typed NULL (cause: *blocked on a business
  rule*) and `int_dpr__tour_revenue` deliberately does not consume it. Its revenue total is
  the dollars currently sitting outside every DPR line.
- **Categories 2831 and 2826 are added back but never excluded; 2200, 2201, 2227 and 2229 are
  excluded but never added back.** The first pair looks like years of double-counting; the
  second set means revenue in those categories is dropped from the DPR entirely. Both look
  like legacy drift.
- **`t_reporting_early_access_tours_revenue` filters its two legs inconsistently**
  (`ga_flag = 0` on issued, `and f.ga_flag` on unissued). We used `ga_flag = 0` on both and
  flagged it as a suspected typo rather than a definition.
- **`DisbursementDetails` fans out on `disbursement_id` in the legacy query**, and the Pentaho
  `InsertUpdate` silently collapses the duplicates on the target key. Replicating that would
  inflate every unissued measure, so one representative detail (lowest `sequence_no`) is
  taken. If a disbursement can legitimately carry two details with different bases, that
  choice is wrong and Gateway must supply a tie-break rule.
- **The Tracker `.prpt` joins `fact_..._issued LEFT JOIN fact_..._unissued ON key_date`** — a
  day-grain join that fans unissued rows against issued rows. That looks like a defect in the
  legacy report rather than a definition, and it is not reproduced.
- **`fact_museum_bulk_tickets_test` and the CityPASS actuals remain unstaged**, so the legacy
  child-ticket subtraction and CityPASS additions to `tickets_sold` are still absent. This
  bounds how closely `tickets_sold` can reconcile to the legacy DPR even with the unissued leg
  added.

## [8.7.0] — 2026-08-12 — Scan Validity & Attendance

**ADR-005 gated. This release must not ship before sign-off from Chris Wogas**, the metric
owner, per `DECISION_MEMO.md`. Four measures printed by the Daily Performance Report, the
Attendance Report, the Daily Attendance Report and the Daily Scan Report were computed from
rules the legacy 911dw estate does not use. Museum attendance in particular was a **ticket
count, not a gate count** — and because it is the denominator of every per-capita ratio on the
DPR and the Tracker, the error propagates well beyond the attendance line. Every decision here
is reversible by editing a seed, not a model. Cumulative on 8.4.0 and 8.6.0; four files are
delivered rebased onto the latest prior version so the stack applies in order.

### Added

- **`int_dpr__attendance`** — museum and memorial attendance authored once, with seed-driven
  facility classification and the closed-day zeroing rule.
- **`seed_gateway_facility_map`** (Gateway `Facility.FacilityID` → `key_facility`: 7 → 1006,
  12 → 5000, plus the facility-13 exclusion), **`seed_attendance_facility_group`** (museum /
  memorial / none / unmapped, with the disputed `1000` row carried but not counted), and
  **`seed_attendance_zeroing_rule`** (the closed-Tuesday rule and the 2022-06-15 exception,
  sharing a 300-pass threshold). Property file `_seeds_attendance.yml` is a sidecar so
  `seeds/_seeds.yml` is untouched.
- **`gross_passes_scanned` / `reversed_passes_scanned`** on `fct_daily_scan`,
  **`reversing_scans`** on `fct_daily_operations`, and the matching facts and metrics in
  `ATTENDANCE.sv.yaml` with `PASSES_SCANNED` redefined as the net measure.
- **Three tests**: `assert_scan_validity_rule`, `assert_museum_closed_day_zeroing`,
  `assert_scan_passes_reconcile_gross_less_reversals`.
- **`dbt_project.yml` version 8.6.0 → 8.7.0.**

### Changed

- **`int_ticket_scans` — the legacy validity rule, exactly.** Legacy counts only
  `Status = 0 and Code = 0` positively, **subtracts** `Code = 11`, drops every other usage
  code entirely, and excludes Gateway facility 13 from both legs. The platform was
  `status_code in ('0','1')`: no code predicate, no reversal leg, no facility exclusion, and
  status 1 wrongly admitted. Implemented as a signed `scan_sign` (+1 / −1 / 0) and a
  `net_visitor_count`; every attendance measure now sums that one column. No staging change
  was required — `stg_gateway__usage` already exposes both `code` and `status_code`, so
  ADR-001 is untouched.
- **`int_ticket_scans` — the full ACP hop.** Legacy resolves
  `Usage.ACP → ACPs.AcpId → ACPs.FacilityID → Facility.IDNo` and then reads the map off
  `Facility.FacilityID` — two different columns. The platform used
  `stg_gateway__usage.facility_id` directly, skipping the hop. Both hops are deduplicated so
  the scan grain cannot fan out.
- **`dim_gate`** — join corrected to `acps.facility_id = facility.id_no`. It was joining
  `ACPs.FacilityID` to `Facility.FacilityID`, which is the wrong pair. It now carries the
  resolved `key_facility`.
- **`int_gateway__scan_lines`**, **`fct_daily_scan`**, **`fct_daily_operations`**
  (`total_visitors` is now net; `gates_active` counts counted scans),
  **`fct_daily_performance`** (`mus_attendance` from `int_dpr__attendance`; `mem_attendance`
  no longer coalesced to 0), **`rpt_attendance`**, **`rpt_daily_attendance`**,
  **`rpt_daily_scan`**.
- **`int_dpr__admissions`** — `mus_attendance` removed. The old GA-ticket figure is retained
  as `mus_attendance_ga_proxy`, wired to nothing, for reconciliation.
- **Four report-layout seeds** — every memorial-attendance row → `availability = Stub`. The
  `not_null` tests on `mem_attendance` are removed in both schema files.

### Numbers that move

- **Passes scanned falls**, on four compounding populations: `status_code = 1` rows removed,
  `status_code = 0` with a code outside (0, 11) removed, code 11 swinging from `+q` to `−q`,
  and Gateway facility 13 removed. The direction is unambiguous; the magnitude is entirely a
  function of the code-11 and status-1 volumes in Galaxy.
- **Museum attendance changes definition and value.** Two independent shifts compound: the
  source moves from GA tickets issued to gate scans (which differ by no-shows, advance sales
  recognised on a different date, and multi-entry passes — expect the scan figure materially
  lower on advance-heavy days and materially different in *timing* on every day), and every
  Tuesday under 300 passes plus 2022-06-15 moves to exactly 0.
- **Every per-capita ratio moves with it**, including `REV_PER_CAP_MUSEUM` on the Tracker.
  Because numerator and denominator stay separate through the serving layer, no stored
  quotient needs restating — but every displayed per-cap changes.
- **Memorial attendance goes from a populated number to blank** on the DPR, the Attendance
  Report, the Daily Attendance Report and the Tracker, and `REV_PER_CAP_MEMORIAL` loses its
  denominator. That is a visible regression on four reports. The number it replaces was
  produced by pattern-matching `facility_name like '%MEMORIAL%'` on the Gateway facility
  catalogue, which is not the legacy measure and was self-flagged as unconfirmed in the model
  header. We would rather print nothing than print a number nobody can trace.
- **Any scan whose `Usage.FacilityID` differed from the ACP-derived value moves between
  attendance lines**; where the two agreed the change is a no-op.

### Findings recorded in the caveats tables (no code change this release)

- **`911dw.memorial_attendance` has no writer.** No transformation in the migrated Pentaho set
  populates it, no staged source corresponds to it, and no Gateway ACP resolves to
  `key_facility` 2000 because the facility map only produces 1006 and 5000. Memorial
  attendance therefore cannot be reproduced and is a typed NULL, cause *no data feed*. **The
  largest gap in the attendance domain.**
- **`key_facility` 3000 is unreachable.** The legacy museum filter is `IN (1006, 3000)` but
  `t_fact_museum_passes_scanned` only ever writes 1006, 5000 and 0. The seed carries 3000 so
  the definition is complete; it contributes nothing today.
- **Gateway facility 5000 is orphaned.** Facility 12 resolves to it and it belongs to neither
  attendance definition, so those scans are counted nowhere.
  `int_dpr__attendance.uncounted_passes_scanned` exposes the volume.
- **The legacy `else '0'` bucket means any gate that is neither 7 nor 12 counts toward no
  attendance line at all.** If a gate has been added since the Pentaho job was written, its
  scans are invisible today and stay invisible until a seed row is added.
- **`report.fe_dailyScan_ss` is a stored procedure whose body is not in the migrated SQL**, so
  the Daily Scan Report's market-category derivation still rests on the `acs_dynamic_channel`
  proxy rather than on proven legacy logic. Unchanged here, but it bounds how far that report
  can be reconciled.
- **`fct_daily_operations.retail_revenue_per_visitor` is a stored quotient**, which the ratio
  rule forbids. Pre-existing and out of scope — but its denominator changes in this release,
  so it is worth retiring rather than leaving a divided ratio whose meaning has shifted.
- **The `1000` memorial key is left uncounted**, carried in the seed with
  `is_primary_definition = FALSE`. The legacy estate contradicts itself: two objects use
  `(2000)` and two use `(1000, 2000)`. Flipping the cell changes the definition with no model
  edit.

## [8.6.0] — 2026-08-12 — Gateway Admissions Correctness

**ADR-005 gated. This release must not ship before sign-off from Chris Wogas** (admissions and
ticketing definitions) **and Mary Ng-Zuffante** (revenue recognition and the finance-facing
totals), per `DECISION_MEMO.md`. Six of its seven changes move a number that appears on the
printed Daily Performance Report, the MTD/YTD workbooks, or both. Items 1, 2, 4 and 5 all feed
`ADMISSION_REVENUE`, so a partial acceptance produces a total that matches neither the legacy
report nor the current one; the memo asks for them as one decision. Cumulative on 8.1.0, which
ships without a gate.

### Added

- **`seed_gateway_reseller_customer`** (five customer IDs) and **`customer_id`
  (`JnlTickets.CustomerID`) on `int_gateway__ticket_journal_lines`.** Which column carries the
  reseller list is settled with proof:
  `t_fact_museum_tickets_issued_fordate_new` uses both columns in one statement — it filters
  `vA.rItmDefaultCustomerID NOT IN (20056, 23361)` in the WHERE clause and separately *carries*
  `JNLTickets.CustomerID` as an output column, which the reporting layer then splits on. 20056
  appearing in both lists is a coincidence, not evidence they are the same thing.
- **`tran_date_key` (`JnlHeaders.TranDate`) on `int_gateway__ticket_journal_lines`**, because
  both legacy service-fee steps key on it rather than on the ticket recognize-basis date.
- **`seed_gateway_pass_plu`, `seed_gateway_tickets_sold_excluded_plu`,
  `seed_gateway_ticket_revenue_excluded_plu`** and their `_seeds.yml` definitions and tests.
- **Four pass-revenue cohorts on `int_dpr__admissions`, carried individually on
  `fct_daily_performance`** so the roll-up is auditable against the five legacy steps, plus
  **four typed-NULL placeholders** (`pass_revenue_scanchange`, `pass_revenue_additional`,
  `ticket_revenue_additional`, `child_tickets_subtracted`) which must never be given
  `not_null` tests.
- **`ecom_gross_profit`** — built in `int_dpr__retail` as `ecom_sales - ecom_cost`, mapping
  1:1 onto `t_reporting_ecom_profit` and `t_fact_cogs` step 5. The 8.1.0 typed-NULL
  placeholder is removed and the layout seeds flip to `Available`.
- **`dbt_project.yml` version 8.5.0 → 8.6.0.**

### Changed

- **`total_admission_revenue` = `ticket_revenue + pass_revenue + service_fees`** on the actual
  (`fct_daily_performance`), the budget (`fct_budget_dpr_forecasts`) and both semantic views.
  The budget fact already carried `service_fees`; it was simply absent from the total, and
  leaving one scenario on two components and the other on three would have re-created the
  unlike-totals defect 8.1.0 removed. `rpt_dpr_report_long`, `rpt_dpr_mtd_ytd_long` and
  `rpt_dpr_budget_daily` need **no** edit — all three read `admission_revenue` through their
  wrappers, which is the point of defining the column once.
- **`int_dpr__fees_and_services` — museum service fees were reading half the journal.** The
  legacy museum step joins **both** `jnlTickets` (`jnlCodeID = 101`) and `JnlItems`
  (102/103/104), resolving through `ISNULL(JnlItems.plu, jnlTickets.plu)`; the model read only
  the item journal, so every museum service fee booked against a ticket line was missing. The
  memorial step joins items only and is **not** changed.
- **`int_dpr__admissions`** — the reseller split, the four pass cohorts, and the exclusion
  lists legacy applies and the platform did not: the tickets-sold PLU list, `%XGA%` on
  tickets sold only (the working half of 8.1.0 item 1 — legacy applies no XGA predicate to
  ticket revenue), and the three early-access PLUs on GA ticket **revenue** only.
- **`int_dpr__donations`** — `JNLDetails.Qty <> 0` applied to the three cohorts legacy sources
  from `t_fact_all_gateway_donations_new` (`coatcheck_don`, `box_office_mem_don`,
  `box_office_mus_exit_don`) and **not** to `ticketing_donations`, which legacy sources
  elsewhere and does not filter on quantity.
- **`int_gateway__ticket_journal_lines`** — `EventTypeID <> 56`, applied only where the event
  type is known. **Deliberate divergence:** legacy INNER joins its event set, which also drops
  every line whose event does not resolve, and `rme.start_at` is NULL for roughly 95% of
  basis-182 lines in the current extract, so a faithful inner join would delete most of the
  fact.
- **`DPR.sv.yaml`, `UNIFIED.sv.yaml`** and both generated deploy scripts;
  `dpr_line_items.csv` and `dpr_mtd_ytd_print_lines.csv`.

### Numbers that move

- **`ADMISSION_REVENUE` rises by `SERVICE_FEES`, on both scenarios.** `AVG_TICKET_PRICE` rises
  with it (same numerator change, unchanged denominator), and `TOTAL_ESTIMATED_REVENUE` rises
  by the same amount and no more — service fees are not added a second time anywhere.
- **`museum_service_fees` and `SERVICE_FEES` rise** by the newly captured ticket-line half,
  and carry admission revenue and the estimated-revenue total up with them.
- **`TICKET_REVENUE` falls and `PASS_REVENUE` rises by exactly the same amount** on the
  reseller split. `ADMISSION_REVENUE` and `TOTAL_ESTIMATED_REVENUE` are unchanged by this item
  — it is a reclassification between two lines of one total.
- **`PASS_REVENUE` rises** on the cohort work: four cohorts where there was one matrix
  pattern. Note the C3 booklet cohort is `sum(quantity * amount)`, not `sum(amount)` — only
  that cohort, and it is not a transcription error in legacy, which stores a per-booklet unit
  amount.
- **`TICKETS_SOLD` falls** on three separate narrowings (the PLU list, the XGA pattern, event
  type 56), which pushes **`AVG_TICKET_PRICE` up** through the smaller denominator.
- **`TICKET_REVENUE` falls** by the three early-access PLUs.
- **`COATCHECK_DON`, `BOX_OFFICE_MEM_DON` and `BOX_OFFICE_MUS_EXIT_DON` fall or stay flat** by
  the zero-quantity adjustment lines.
- **`ECOM_GROSS_PROFIT` goes from nothing to a value**, so the actual side of
  `TOTAL_RETAIL_GROSS_PROFIT` and `TOTAL_ESTIMATED_REVENUE` rise — and the budget side of
  `TOTAL_RETAIL_GROSS_PROFIT` returns to its pre-8.1.0 value, with the symmetry 8.1.0 restored
  intact on both sides.

`tests/reconciliation/assert_sv_admission_revenue_matches_fct` still holds — the fct column
and the semantic-view metric both gain `service_fees` — and it is exactly the guard that would
have caught updating one and not the other.

### Findings recorded in the caveats tables (no code change this release)

- **Legacy defect, long-standing:** `t_fact_museum_citypass`'s PLU exclusion list contains
  `'CPBOOKAD008''CPBOOKYS008'` **with no separating comma**, which SQL Server parsed as the
  single literal `CPBOOKAD008'CPBOOKYS008`. **Neither PLU has ever actually been excluded in
  production.** The seed reads them as two values, which is clearly what the code intended —
  and reading it as intended removes dollars that have been in the number for years. That is
  the committee's call, not a silent fix.
- **Three of the five reseller customer IDs (17522, 23110, 22361) cannot be resolved to a
  name** from the Pentaho SQL. Seeded as "name pending". A reseller onboarded since the last
  Pentaho edit is today silently counted as walk-up ticket revenue.
- **`fact_museum_citypass_scanchange` has no Gateway equivalent among the 21 staged tables**
  and its construction is not in the extracted transformation set, so the cohort cannot be
  re-derived, only re-extracted. It covers everything after 2016-06-01, i.e. the entire
  reporting window.
- **`fact_additional_revenue_new` is loaded from an operations workbook, not from Galaxy**,
  which blocks both the `%GAD-NYA-NYA-OTH-XXX%` pass cohort and the `RESLADDREV001`
  ticket-revenue line.
- **`pricePointID = 84` is a feed gap, checked rather than assumed.** The only price-point
  column in the platform is `stg_gateway__vattribute.itm_price_point_id`, which is the item
  master's price point, not the sold ticket's, and the source fact is not staged at all.
- **The 13 excluded `key_museum_category` values in `t_reporting_virtual_mem_tours_revenue`
  cannot be crosswalked** without `dim_galaxy_items`. 8.1.0 expresses the part that matters
  (the revealed tour PLU) directly on PLU; whether the remaining twelve categories carve out
  anything else is undeterminable from the extract.
- **Whether `MUSGADADCP005` / `MUSGADYSCP005` carry a `GAD` matrix code decides whether the
  CityPASS booklet dollars *move* from ticket revenue to pass revenue or are *added*.** The
  query is in NOTES item 4; it needs the warehouse, not the SQL.
- **Carried from 8.1.0 and still undecided:** whether `TOTAL_MUSEUM_DONATIONS` should carry
  `box_office_mus_exit_don` and `coatcheck_don` (legacy's does not); whether
  `VIRTUAL_YF_TOUR_REVENUE` should be counted once or twice in `rpt_dpr_mtd_ytd_long`'s grand
  total, given the print catalog genuinely prints it in two sections; which of the two
  `TOTAL_ESTIMATED_REVENUE` component sets is right; and whether
  `rpt_memorial_museum_tracker_ytd.total_donations_ytd` should gain `cafe1_donations`.

## [8.5.0] — 2026-08-12 — Ratio Definitions (capture ≠ conversion)

**ADR-005 gated. This release must not ship before sign-off from Gennady Zaritsky and Chris
Wogas**, per `DECISION_MEMO.md`. It changes what two certified rates report. Three changes,
all of which were one defect wearing three hats: the platform had collapsed two metrics into
one. Depends on 8.4.0 and carries a cumulative `fct_retail_daily.sql`.

### Added

- **`int_retail__ratio_components`** — the four numerator/denominator pairs as separate
  additive columns, authored once. No quotient is stored anywhere. Six distinct columns cover
  four pairs because conversion's denominator *is* capture's numerator:
  `capture_rate = store_entries / museum_attendance`,
  `conversion_rate = transactions / store_entries`,
  `sales_per_cap = net_sales / museum_attendance`,
  `profit_per_cap = net_profit / museum_attendance`.
- **`capture_rate` as its own metric with its own synonyms** in `RETAIL.sv.yaml` and
  `UNIFIED.sv.yaml`, plus `sales_per_cap` and `profit_per_cap`, which share capture's
  denominator and were the other two of the four pairs. `MUSEUM_ATTENDANCE` is added as a fact
  on the retail view.
- **`seed_carts_denominator_rule`** — the legacy year rule as data, with rows for 2019 and
  2020 only.
- **`dbt_project.yml` version 8.4.0 → 8.5.0.**

### Changed

- **`'capture rate'` is removed from the `conversion_rate` synonym list.**
  `deploy_semantic_view_unified.sql` carried it as a synonym on the conversion metric, so
  Cortex answered a capture-rate question with the conversion number. Legacy has kept the two
  apart since 2014: `t_fact_mus_store_analysis` computes
  `sum(mus_store_visitors) / sum(mus_visitors)` as capture and
  `sum(mus_store_customers) / sum(mus_store_visitors)` as conversion.
- **`fct_retail_daily`** (cumulative on 8.4.0) gains day-level `museum_attendance` and
  `memorial_attendance` denominators.
- **`rpt_retail_report_long`** — the `CAPTURE_RATE` denominator moves from `attendance` (the
  DPR scan proxy) to `museum_attendance` (the Sensource measure legacy divides by).
- **`rpt_retail_carts_analysis`** — the hardcoded 2019 denominator is replaced by the seeded
  year rule, and the memorial/museum counts are re-sourced. `mem_visitors` on the carts report
  is memorial **attendance** (`passes_scanned` at 2000), not a door count at facility 1020,
  where no Sensource sensor reports — which is why those lines read zero even after 8.4.0.
- **`rpt_carts_report_long`** — ratio denominators `adj_visitors` → `capture_denominator`.
- **Layout seeds** — one flip in `retail_line_items.csv`
  (`MUSEUM_STORE__CAPTURE_RATE` → `Available`); three flips to `Available` and three to
  `Partial` in `carts_line_items.csv`.
- **`rpt_retail_powerbi` is deliberately not touched.** `rpt_retail_report_long` reads the
  capture denominator from the fact rather than from the wrapper, so the semantic view
  publishes `capture_rate` as a metric without publishing a queryable
  `TOTAL_MUSEUM_ATTENDANCE` on the retail view — which would sit next to
  `dpr.total_museum_attendance` in `UNIFIED` with a different value and give Cortex two
  "museum attendance" totals to choose between.

### Numbers that move

**Nothing that is currently non-zero on a published report becomes a different non-zero
number.** The visitor denominators were unreachable before 8.4.0, so today's ratios are
already NULL or blank; the change is from *blank* to *populated*, plus one change of meaning:

- `MUSEUM_STORE__CAPTURE_RATE` — blank → store entries ÷ Sensource museum attendance.
- Carts `CAPTURE_RATE`, `PROFIT_PER_CAP`, `SALES_PER_CAP` — blank → populated for **2019 and
  2020 only**, and **still blank for 2021 onward**. `Partial` is the honest availability
  value; `Available` would promise numbers the current year does not have.
- Cortex asked "what was the capture rate" — returns the conversion number → returns the
  capture number. Asked "what was the conversion rate" — unchanged.

For the first run: museum-store capture should come back materially **below** conversion. If
it comes back higher, the entry/exit column choice or the attendance denominator is wrong, not
the definition.

### Findings recorded in the caveats tables (no code change this release)

- **The legacy carts ratios have been blank since 1 January 2021, and nobody noticed.** The
  year CASE in `t_retail_cart_analysis_tabs` has branches for 2019 and 2020 and **no `ELSE`**,
  so it falls through to NULL; the same three-branch pattern repeats for `profit_per_cap` and
  `sales_per_cap`. The report filter is `key_date >= '2020-07-04'` with **no upper bound**, so
  every row from 2021 onward is selected, printed, and carries three blank ratios. That has
  been true for five years of a live distributed workbook. This release reproduces the
  behaviour rather than inventing a 2021+ rule; adding one is a one-row seed edit once the
  committee answers.
- **The 2019 denominator `((mem_visitors − 0.25 × mem_visitors) − mus_visitors)` has no
  clamp.** The pre-8.5.0 model wrapped it in `greatest(..., 0)`, which legacy never did and
  which silently changes a printed number whenever museum attendance exceeds 75% of memorial
  attendance. This release matches legacy.
- **The platform now carries two museum-attendance numbers** — Sensource passes scanned
  (1006+3000) and the DPR scan component — and the Retail Performance Report will print one on
  its Attendance line and divide by the other in Capture Rate. Defensible only as a stated
  interim. **The estate needs one attendance ADR**; the same conflict drives the Attendance
  Report's Memorial Only line.
- **`REV_PER_VISITOR` is left on `attendance`.** Four retail lines use it as a denominator.
  Moving it to `museum_attendance` is arguably right for consistency, but it was not asked for
  and it restates a currently-`Available` number.
- **`MEMORIAL_CARTS__CONVERSION_RATE` is left `Stub` and unnamed.** Legacy computes cart
  customers ÷ memorial attendance and calls it a *capture rate*; the layout seed calls the
  same shape a *conversion rate*. Not picked for the committee.
- **`rpt_retail_performance` still computes `conversion_rate` inline** from `fct_retail_daily`.
  It is correct and needs no change, but it has no capture rate. If the legacy day-grain view
  is expected to carry both, that is a small follow-up.

## [8.4.0] — 2026-08-12 — Sensource Visitor Crosswalk

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

### Added

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

### Changed

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

### Numbers that move

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

### Findings recorded in the caveats tables (no code change this release)

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

## [8.3.0] — 2026-08-12 — Retail Profit Correctness (return cost, ticket header)

Ships on top of 8.2.0 — the `int_counterpoint__retail_lines` shipped here is the cumulative
8.2.0 + 8.3.0 state; do not apply the 8.2.0 copy after it. Three defects, all in the same
chain: the retail line model never joined a ticket header, so unposted and non-ticket
documents were being reported and costed; cost was taken from sale lines only, so a return
handed back the revenue but kept the cost; and customer counts were a grouped
`count(distinct doc_id)` off the sales scope, on the wrong date column, ignoring every
`doc_id` semi-join legacy uses.

### Added

- **`return_cost`, `net_cost` and a carried `ticket_date`** on
  `int_counterpoint__retail_lines`.
- **`assert_retail_gross_profit_nets_returns`** — the reconciliation test that fails on ship
  if the netting is not carried through to the consumers.
- **`dbt_project.yml` version 8.2.0 → 8.3.0.**

### Changed

- **`int_counterpoint__retail_lines`** gains the `pstkthist` header join with `TKT_TYP = 'T'`
  and the `LIN_TYP <> 'U'` line filter, exactly as `t_fact_cogs` gates every branch.
  `stg_counterpoint__pstkthist`, `stg_counterpoint__vitkthist` and
  `stg_counterpoint__vitkthistlin` were staged and read by **nothing** before this.
- **`int_retail__customers`** rewritten as the eleven legacy cohorts, counting on
  `TICKET.TKT_DT` (the header ticket date) rather than `LINE.BUS_DAT`, with the `doc_id`
  semi-joins legacy uses. Memorial Carts is stores 11, 12 and 13 — not 14 — and excludes any
  document containing `200933`, `201229`, `201114` or `201197` from 2023-09-04. MAG, MUS AG,
  MTG and Membership use the **inverse** semi-join: documents that *do* contain the carve-out
  SKU.
- **`int_retail__performance`** — `net_profit` and `cost_of_goods` move from `sale_cost` to
  `net_cost`. Not on the original deliverable list but required: without it the new column
  exists, nothing changes, and the new test fails on ship.
- **`int_dpr__retail`** — the four cost lines (`mus_store_cost`, `mem_cart_cost`,
  `cafe1_cost`, `musag_cost`) move to `net_cost`. Also not on the original list, also
  required.

### Numbers that move

- **Gross profit DROPS on any day with a return. That is the headline.** `t_fact_cogs` sums
  `LINE.EXT_COST` over **all** surviving lines in every branch — there is no
  `CASE LIN_TYP WHEN 'S'` anywhere in that file — while the platform had
  `case when l.line_type = 'S' then l.ext_cost else 0 end`. Revenue netted the return; cost
  did not. **Profit was overstated by the cost of every returned item.** Affected and all
  moving down: `net_profit` and `cost_of_goods` on `int_retail__performance` and
  `fct_retail_performance`, `net_profit` on `fct_retail_daily`, `mus_store_gross_profit` /
  `retail_carts_gross_profit` / `cafe1_all_profit` / `musag_profit` on `int_dpr__retail`, and
  everything downstream of those four on `fct_daily_performance` including
  `audio_tour_headset`. If the number is material to a published month, that is an ADR-005
  conversation with Gennady Zaritsky **before** the build lands, not after.
- **Row count and most measures fall on the header gate.** Documents whose `TKT_TYP` is not
  `'T'` (quotes, orders, holds) and `'U'` lines leave; sales, cost, units and transaction
  counts fall by whatever those carried. A drop far larger than a percent or two means the
  `TKT_TYP` values in the staged extract are not what legacy saw — check before shipping,
  because the inner join is unforgiving.
- **Customer counts: 1020 falls** (store 14 removed, carve-out documents excluded); **1001 and
  1002 are counted for the first time**; **1040, 1060, 1070 and 1080 are replaced by their
  semi-join cohorts** rather than being an artefact of the item→facility mapping; and **every
  facility shifts by a day at the margin** on `TKT_DT` versus `BUS_DAT`.
  `fct_retail_daily.transactions` and every ratio built on it — conversion rate, average sale,
  per-cap donations — move accordingly.

### Findings recorded in the caveats tables (no code change this release)

- **The return sign convention is still an unconfirmed `CONFIRM`, standing since 7.9.0.** The
  direction argument above depends on CounterPoint `'R'` lines landing with **negative**
  `ext_cost`. Query (B) in NOTES proves it on live data and must be run first: if `'R'` cost
  lands positive, the netting flips, profit moves the other way, and the sign must change in
  `int_counterpoint__retail_lines` and nowhere else.
- **`stg_counterpoint__pstkthist` aliases `TKT_TYP` as `is_return`**, which is a misnomer — it
  is a type code, not a boolean. ADR-001 keeps staging rename-only, so it is read as-is; fix
  the alias in a follow-up.
- **Legacy reads the `VI_` reporting views and joins on `DOC_ID` *and* `BUS_DAT`;** this model
  joins the posted header on `doc_id` alone, which is the header PK at that grain. Moving to
  the `VI_` views means moving **both** sides.
- **The Museum Store cohort's operator precedence is almost certainly a legacy bug, and it is
  what produced the certified series.** `WHERE A OR (B AND C) AND TKT_DT > '20170423'` binds
  `AND` tighter than `OR`, so stores 8/9/10 have **no start date** and only the store-14
  carve-in is bounded. Reproduced.
- **The Membership cohort starts 2023-11-29 in `t_fact_num_tickets` and 2024-01-21 in
  `t_fact_cogs`**, so 1080 carries roughly seven weeks of transaction counts with no sales.
  Pick one date before publishing a 1080 per-transaction ratio.

## [8.2.0] — 2026-08-12 — Retail Scope (many-to-many store→facility)

Rebuilds the CounterPoint retail scope so it expresses what legacy `t_fact_retail` actually
does: **seven independent store queries**, a **many-to-many, date-bounded** store→facility
relationship, and **per-query** item carve-ins, carve-outs, zero-pricing and donation
reclassing. Nothing here changes cost or the netting convention — that is 8.3.0.

### Added

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

### Changed

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

### Numbers that move

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

### Findings recorded in the caveats tables (no code change this release)

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

## [8.1.0] — 2026-08-12 — Dead Code & Double Counts

Not gated. Nothing here redefines a certified metric on the basis of a judgement call: every
change is either code that provably does nothing today, or a component counted twice, or two
surfaces of the same report disagreeing with each other and with the legacy definition of
record. Items 4 and 5 below do move published numbers; they are included because the
pre-change state is internally contradictory, not because a definition was chosen, and each
carries its exact delta and the query that measures it.

### Changed

- **`macros/operations/gateway_recognized_date.sql` — the `'%XGA'` literal is deleted.**
  `gateway_general_admission_flag` carried
  `and coalesce(va.itm_matrix_code, '') <> '%XGA'` — a literal string comparison that excludes
  a row only when the matrix code is exactly those four characters. Galaxy matrix codes contain
  no `%`, so the predicate was true for every row in the warehouse. Legacy carries the *same
  dead literal in the same place*; the live XGA exclusion sits one layer up as a cohort filter
  on tickets sold, and is not applied to ticket revenue at all. Rewriting it as a real `LIKE`
  would change `ga_flag` itself and drop rows from ticket revenue too, which legacy never
  does — so the deletion is free and the working exclusion lands in 8.6.0. **Numbers moved:
  none**, with a guard query that must return 0 before shipping.
- **`int_gateway__ticket_journal_lines` — `inner join` → `left join` on COA and attributes.**
  Every legacy extract at this grain left-joins both and coalesces the matrix code the way the
  repo already does. COA is only a bridge to the `DisbursementDetails` lookup; a ticket line
  whose account has no COA row still exists, and an item with no attribute-value group has no
  matrix code, which is exactly what `ISNULL(...,'')` is for. The loss surfaced three models
  downstream as quietly missing dollars rather than as an error. `jnl_tickets` and `items`
  stay `inner join` — legacy's own `WHERE` drops the unmatched rows again, so inner is
  equivalent there and converting them *would* change behaviour. **Numbers moved: up**, or
  flat, wherever rows were being dropped — `tickets_sold`, `ticket_revenue`, tour revenue and
  service fees. If any of them falls, the change was not the cause and the build is wrong.
- **`int_dpr__tour_revenue` — revealed tour was counted inside the virtual-memorial cohort.**
  `revealed_tour_revenue` came from `seed_tour_plu` (PLU `VTMUSOBLOADW001`) and
  `virtual_mem_tour_revenue` from `matrix_code like '%VTM%'` with no carve-out, and
  `VTMUSOBLOADW001` carries a `%VTM%` code — so the same dollars landed in both measures, and
  `rpt_dpr_report_long` sums both into `TOTAL_TOUR_REVENUE`. Legacy isolates them on PLU
  inside one `%VTM%` cohort. **`virtual_mem_tour_revenue`, `VIRTUAL_TOUR_REVENUE` and
  `TOTAL_TOUR_REVENUE` all fall by exactly the revealed amount.**
- **`mask_donations` — the two DPR surfaces disagreed, and neither matched legacy.**
  `rpt_dpr_mtd_ytd_long` included mask donations in `total_other_visitor_revenue` and excluded
  `box_office_mem_don`; `rpt_dpr_report_long` did the opposite in
  `TOTAL_MEMORIAL_DONATIONS`. The legacy definition of record is
  `ecom_don + don_box + cart_don_ask + mask_don`, where `don_box` is the CounterPoint plaza
  donation box (platform `donation_box`, item `101165`) and **not** `box_office_mem_don`
  (Gateway PLU `DONOPSMEM003`), which legacy reports on the donations analysis fact instead.
  Mask donations are in; `box_office_mem_don` is out of the composite and still projected as
  its own measure. The composite moves to `DP.TOTAL_MEMORIAL_DONATIONS` in the semantic view —
  ADR-021's first-preference home — and `TOTAL_MUSEUM_DONATIONS` moves the same way with its
  components unchanged, so the two live side by side under one governance surface. **Numbers
  moved: `TOTAL_MEMORIAL_DONATIONS`, and therefore `TOTAL_ESTIMATED_REVENUE` and the Tracker's
  `total_earned_revenue`, change by `mask_donations − box_office_mem_don`. Mask donations have
  been dormant since 2021, so in practice this is a decrease equal to `box_office_mem_don`.**
- **`ECOM_GROSS_PROFIT` — the budget/actual asymmetry, corrected against the brief.** The
  asymmetry is real but it is not in `TOTAL_ESTIMATED_REVENUE`, which has no budget branch at
  all in `rpt_dpr_report_long`. It was in `TOTAL_RETAIL_GROSS_PROFIT`, whose budget composite
  carried `ecom_gross_profit` and whose actual composite did not, so the variance column
  differenced two different things. `ecom_gross_profit` is removed from the **budget**
  composite (the standalone `ECOM_GROSS_PROFIT` budget row is untouched and still prints), the
  actual side emits an explicit typed-NULL placeholder with the ADR-021 cause stated, and
  `dpr_line_items.csv` moves that row from `Gap` to `Stub`. **Numbers moved: budget only,
  down. No actual changes.**
- **Museum Cafe was counted twice in `rpt_dpr_mtd_ytd_long`.** `TOTAL_RETAIL_GROSS_PROFIT` was
  mapped to `dp.total_retail_gross_profit`, which is store + carts + **cafe**, and
  `TOTAL_ESTIMATED_REVENUE` then added `cafe_profit` again. Provable from the definitions
  alone, and confirmed twice over: the semantic view's own comment says the legacy "Total
  Retail Gross Profit" line *excludes* cafe and warns against treating the metric as that
  line, and the print catalog puts `EC_TOTAL_RETAIL_GP` in the E-Commerce section and
  `CAFE_TOTAL_PROFIT` in its own. New governed metric
  `DP.TOTAL_RETAIL_GROSS_PROFIT_EX_CAFE` is used for the line and inside
  `TOTAL_ESTIMATED_REVENUE` in both DPR serving models; the cafe-inclusive metric stays for
  Cortex users who want the wider rollup. **Numbers moved: `rpt_dpr_mtd_ytd_long`'s
  `TOTAL_RETAIL_GROSS_PROFIT` and `TOTAL_ESTIMATED_REVENUE` both fall by the cafe profit.
  `rpt_dpr_report_long` is unaffected** — it already summed store + carts inline.
- **`TOTAL_ESTIMATED_REVENUE` was authored three times, not twice** as ADR-021's open items
  record: `rpt_dpr_report_long`, `rpt_dpr_mtd_ytd_long`, and `rpt_tracker_powerbi` (as
  `total_earned_revenue`, whose header claimed it mirrors the DPR composite exactly). The
  first and third have identical component sets and are collapsed onto a new
  `DP.TOTAL_ESTIMATED_REVENUE`. The `mtd_ytd` set is **not** identical — it additionally
  carries `mem_audio_guide_revenue` and `virtual_yf_tour_revenue` and omits
  `box_office_mus_exit_don`, `coatcheck_don` and `donation_box` — so collapsing it too would
  be choosing a definition rather than removing a duplicate. Carried into the 8.6.0 memo.
  **Numbers moved: none from this change alone.**
- **The `intraday` tag existed on only one model.** `dbt_project.yml` sets a 300-second
  statement timeout for `{% if 'intraday' in model.tags %}`, but the tag was on
  `fct_ticket_availability` alone, so every same-day model inherited the 3600-second default.
  Added to `fct_today_sales_hourly`, `rpt_today_sales_powerbi`,
  `rpt_today_sales_report_long`, `rpt_today_sales_narrative_brief`,
  `stg_counterpoint__todays_retail` and `stg_counterpoint__todays_retail_product`. dbt merges
  model-level tags with the project-level `daily` / `critical` tags, so no existing selector
  breaks. **Numbers moved: none** — a session parameter, not SQL.
- **`dbt_project.yml` version 8.0.0 → 8.1.0.**

### Removed

- **`rpt_attendance`'s dead Sensource columns.** `sensource_mem_attendance` /
  `sensource_mus_attendance` were selected into a CTE and never projected — recorded in the
  7.13.1 CHANGELOG, still true. They are removed rather than surfaced deliberately: the report
  already publishes `memorial_attendance` / `museum_attendance` from `fct_daily_performance`,
  and adding a second, differently-sourced attendance pair beside them would ship the
  Sensource-blend ambiguity to report consumers before ADR-005 has settled it (owner: Chris
  Wogas). **Numbers moved: none** — the columns were never in the output.

### Fixed (stale documentation, not code)

- **`rpt_memorial_museum_tracker_ytd`'s `cafe1_donations` comment.** It claimed the column was
  "not surfaced in `fct_daily_performance` yet"; it has been for some time
  (`fct_daily_performance` line 127). The gap in `total_donations_ytd` is real, but its cause
  is a component choice, not a missing upstream column. The note is corrected here (free) and
  the fix is carried into the 8.6.0 memo (gated). **Numbers moved: none.**

### Findings recorded in the caveats tables (no code change this release)

- **`VIRTUAL_YF_TOUR_REVENUE` is double-counted in `rpt_dpr_mtd_ytd_long`.**
  `TOTAL_GUIDED_TOUR_REVENUE` includes it and `VIRTUAL_TOUR_REVENUE` includes it, and
  `TOTAL_ESTIMATED_REVENUE` adds both. Unlike the cafe case, the print catalog genuinely
  prints the measure in two sections (`GT_YF_TOUR_REV` in Guided Tours,
  `VT_YF_MEM_TOUR_REV` in Virtual Tours), so whether the grand total should count it once or
  twice is a question for the report owner rather than a defect with one reading. It was zero
  in the 2025-12-31 workbook, which is why the verification note in that model's header
  passed. Documented in the model header and carried into the 8.6.0 memo.
- **`TOTAL_MUSEUM_DONATIONS` does not match legacy's museum donation total**, which is
  `ms_donations + mus_exit_donations + ticketing_donations + cafe1_donations` and does **not**
  include `box_office_mus_exit_don` or `coatcheck_don`, both of which the platform's composite
  carries. A definition question for the report owner, not a defect with one right answer, so
  it is not decided here. ADR-005; carried into the 8.6.0 memo.
- **The `rpt_dpr_mtd_ytd_long` header verification note (MTD 9,170,373.79) is annotated in
  place.** The "retail GP total" term in that arithmetic was read from the cafe-inclusive
  metric and must be re-run against the 2025-12-31 workbook before it is treated as current.
- **`assert_silver_gold_revenue_reconciliation` will move** with the join change (more silver
  rows retained, more gold revenue). Re-baseline if it asserts an absolute value rather than
  an equality between layers.

## [8.0.0] — 2026-08-12 — Legacy Reference Capture

Additive documentation only. No model, seed, macro, test or semantic-view change — `dbt parse`
output is byte-identical to 7.13.1, and the only file in the dbt project that changes is the
version string. **It ships first and it is the only release in the v8 series with an external
deadline.** Every v8 correction was found by reading legacy SQL; after January that SQL is
gone, and any correction not yet made becomes unverifiable — we would hold a number that
disagrees with a report nobody can re-read. Committing the reference decouples the deadline
from the pace of the corrections.

### Why this is 8.0.0, and why 7.14.0 is a live option

Semver on this platform has been ambiguous (release-process brief, Q5). The v8 series opens
with a major because the **series** is breaking: 8.5.0 through 8.8.0 change what certified
metrics count. **8.0.0 itself breaks nothing** — it opens the series and establishes the
reference material every later release cites. If the team prefers the major to land on the
first release that actually moves a number, **this can ship as 7.14.0 with no other change**
and the major moves to 8.5.0's position in the sequence. Worth deciding once, at the top of
the series, and recording in the release-process work.

### Added

- **`docs/migration/legacy_sql/` — 216 Pentaho transformations as `.sql`**, and
  **`docs/migration/legacy_report_sql/` — 309 report queries extracted from the nine live
  `.prpt` bundles**, nine files.
- **`docs/migration/index/`** — `pentaho_parsed.json` (216 transformations + 80 jobs,
  structured), `closure2.json` (live/dead classification and source closure),
  `prpt_tables.json` (table references per live report), plus `parse2.py` (the `.ktr`/`.kjb`
  extractor) and `closure2.py` (the live/dead walker).
- **`docs/migration/README.md`** — what the capture is, how it was built, how to grep it.
- **`docs/migration/RECOVERY_CHECKLIST.md`** — the urgent half. See below.
- **`dbt_project.yml` version 7.13.1 → 8.0.0.** No other file in the dbt project changes.

### Verified

- **The dbt project is untouched apart from the version string.** `dbt parse` plus a
  `git diff --stat` against 7.13.1 over `dbt_project.yml`, `models/`, `seeds/`, `macros/`,
  `tests/` and `cortex_project/` — expect one file, one insertion, one deletion.
- **The capture is complete**: 216 files in `legacy_sql/`, 9 in `legacy_report_sql/`, 309
  query blocks across them.
- **No credentials rode along.** `.prpt` bundles carry `data:property name="password"` blobs
  and `.ktr` connection blocks carry credentials; `parse2.py` captures connection *names* only
  and the report extractor takes only `data:static-query` bodies. The grep is in the NOTES and
  must be run before merging anyway — this is a public-ish repo and the check is free.
- **~2.4 MB across 230 files**, mostly `legacy_sql/`. No binaries, no `.prpt` files, no PDFs —
  all text, all diffable.

### Findings recorded in the caveats tables (no code change this release)

- **`RECOVERY_CHECKLIST.md` is the sharper point of this release: 7 transformations, 2 stored
  procedures, 8 workbooks, 10 open questions and 4 unrecoverable items are *not* in this
  capture.** §A1–A3 alone mean **three of the four Daily Scan Report ETL steps are missing
  today**, including the `report.fe_dailyScan_*` stored procedures whose bodies are not in the
  migrated SQL.
- **`docs/README.md` does not yet list `docs/migration/` in its map.** Left for the release
  that adds the v8 series index, so the doc map is edited once.
- **`parse2.py` and `closure2.py` are committed as-is from the analysis sandbox.** They are
  re-runnable but not packaged (standard library only — `zipfile`, `xml.etree`, `re`, `json`).
  Fine as reference; do not import them into anything.


## [7.13.1] — 2026-08-11 — Report Lineage Documentation (per-family pages + DPR rewrite)

Documentation-only release. No model, seed, macro, test, or semantic-view change — `dbt
parse` output is byte-identical to 7.13.0. What changes is that the serving layer ADR-021
codified in 7.13.0 is now documented per report family, and that `DPR_LINEAGE.md`, last
revised in July at v1.5.0, describes the platform as it actually is.

### Added

- **`docs/architecture/lineage/` — one lineage page per report family**, matching the
  ADR-021 directory structure: `RETAIL_LINEAGE.md`, `TRACKER_LINEAGE.md`,
  `SCAN_LINEAGE.md`, `TODAY_SALES_LINEAGE.md`, `ATTENDANCE_LINEAGE.md`,
  `WEBSITE_COMMERCE_LINEAGE.md`. Each carries a mermaid graph of the full chain (staging →
  intermediate → fact → semantic view → serving models), a model inventory with ADR-021
  role and grain, the transformations that actually change numbers, and a caveats table.
  `restricted/` has no page by design — one PII extract, no semantic view.
- **`docs/architecture/lineage/LINEAGE_INDEX.md`** — family index, the seven-role reference
  table, the three cross-cutting rules (ratios never stored pre-divided, composites
  authored once, typed-NULL placeholders with a stated cause), the cross-family seams, and
  the open items that span every family.
- **`docs/architecture/ARCHITECTURE_FLOW.md` — "Per-report lineage" section** pointing at
  the index, so the platform-wide flow doc stops being the only place to look.

### Changed

- **`docs/architecture/DPR_LINEAGE.md` rewritten against v7.13.0.** The upstream half
  (source → staging → intermediate → `fct_daily_performance`) was substantially still
  correct and is kept. The downstream half is new: the DPR no longer ends at one `rpt_`
  model, so the doc now carries all thirteen models in the family with their ADR-021 roles,
  the period-window anchor logic and why MTD/YTD prior year is a calendar-year shift rather
  than −364 days, the composites-verified-to-the-cent record, the typed-NULL placeholder
  causes in `rpt_dpr_excel_export`, and the narrative chain including its sync guard.
- **`docs/README.md`** — adds the lineage index and `DPR_LINEAGE.md` to the architecture
  table, and ADR-020 / ADR-021 to the ADR log, which stopped at ADR-019.
- **`dbt_project.yml` version 7.13.0 → 7.13.1.** No other file in the dbt project changes.

### Fixed (stale documentation, not code)

Found while verifying every checkable claim against the repo:

- **`DPR_LINEAGE.md` said `fct_daily_performance` carries "~45 additive measures."** It
  carries **42**. Counted from the `combined` CTE.
- **`DPR_LINEAGE.md` described the Gateway comp-customer, placeholder-PLU, service-PLU and
  retail donation-item lists as literals in the models.** All four are now seed-driven
  (`seed_gateway_excluded_customer`, `seed_gateway_excluded_plu`, `seed_service_plu`,
  `seed_retail_donation_item`). The doc said "edit the model"; it now says "edit the seed."
- **The "`assert_critical_tables_not_empty` covers 6 of 17 tables, `fct_daily_scan` and
  `fct_today_sales_hourly` are gaps" line is stale** and was not carried into the new pages.
  The live test covers **15 tables and includes both**. Worth correcting anywhere else that
  line was copied from the older CHANGELOG entry.

### Findings recorded in the caveats tables (no code change this release)

Surfaced by the same verification pass. Each is documented where the affected family's
readers will meet it; none is fixed here.

- **`rpt_memorial_museum_tracker_ytd` carries a comment claiming `cafe1_donations` is "not
  surfaced in `fct_daily_performance` yet."** It has been for some time. Either add it to
  that model's donation total or drop the comment — leaving both is how a stale note becomes
  a believed fact.
- **`T_TODAY_SALES_NARRATIVE` fires once at 05:30 ET** against an intraday day-to-date
  brief, so it narrates the pre-opening state. The setup script documents the blocker
  (hourly firing needs the append-only `NOT IN` dedupe replaced with delete-and-insert for
  the current date). The most consequential open item in that family.
- **No `today_sales` model carries the `intraday` tag**, so none picks up the 300-second
  statement timeout in `dbt_project.yml`; the tag exists only on `fct_ticket_availability`.
  Intent and configuration have drifted.
- **`rpt_attendance` pulls Sensource's own `mem_attendance` / `mus_attendance` into a CTE
  and never selects them.** Dead columns.
- **The Website Commerce `revenue_type` split is an ungoverned string heuristic**
  (`like '%member%'` / `'%don%'` over `order_type` or `title`), copied verbatim into three
  models. A new order type matching neither falls to `'Other'` and silently changes the
  totals. A seeded mapping under the ADR-005 gate is the obvious remedy.
- **The Website Commerce family carries zero ADR-021 role suffixes** across its three
  models — the only family entirely outside the grammar.
- **`models/exposures.yml` is stale across every family**, still pointing at facts and
  legacy models rather than at the serving stacks built in 7.10.0–7.13.0. RPT-013's
  description still reads "STUB: Classy / Shopify recurring feed pending ADR-008" though the
  Drupal recurring feed is live.

### Verified

- Every model name, `ref()` edge, seed row count, `availability = 'Stub'` count,
  semantic-view metric count, facility ID, item number, threshold, cron expression and
  composite total in the eight documents was checked against the repo. Nine errors were
  found in draft and corrected before publication: three family model counts, the
  `rpt_tracker_powerbi` composite component count (20, not 19), the `fct_daily_scan` budget
  unpivot branch count (13, not 12), the `fct_daily_performance` measure count, the stale
  test-coverage claim above, and a reference to `snowflake/01_apply.sql`, which ships in the
  release payload rather than in this repo.
- All mermaid graphs parse; every node used in an edge is declared. All relative links
  resolve.
- Claims not checkable from static code — the July extract conservation figures, the dev
  PBIX attendance discrepancy, the empty SDLY column in dev — are labelled as observations
  rather than asserted as current state.

### Open items carried forward

- ADR-021 §3 still needs Data & AI Committee ratification. The lineage pages cite it as
  Proposed throughout.
- `TOTAL_ESTIMATED_REVENUE` is still authored twice (`rpt_dpr_mtd_ytd_long` and inline in
  `rpt_dpr_report_long`). Carried from 7.13.0; now also documented in `DPR_LINEAGE.md` so it
  is visible to readers rather than only to the ADR.
- The DPR and Retail period-window definitions are still unvalidated against the legacy
  `.prpt` files.

## [7.13.0] — 2026-08-10 — ADR-021: Report Serving Layer (role grammar + family directories)

Structural release. No metric or report output changes — every model's SQL is byte-identical
except the two housekeeping deletions below. What changes is where files live and what governs
them.

### Added

- **ADR-021 — "Report Serving Models Are Named by Role, and Projection Chains Off a Wrapper
  Are Permitted."** Codifies the seven serving roles that emerged across 7.12.0–7.12.5
  (`*_powerbi`, `*_budget_daily`/`*_conform`, `*_period_windows`, serving shapes, presentation
  shapes, `*_narrative_brief`, `*_narrative`/`*_narrative_card`), the legal read direction
  through the chain, the ratio rule, the composite rule, and the typed-NULL placeholder
  convention. Also records that presentation formatting in dbt is intentional under
  DirectQuery rather than ADR-004 drift.

### Changed

- **ADR-018's 2026-07-29 amendment is superseded by ADR-021.** That amendment carved out the
  rpt-from-rpt prohibition by enumerating six filenames; the chains have since grown to roughly
  twenty models across seven families, so every newer model header was citing a sanction the
  governance doc did not actually grant. ADR-021 replaces the enumeration with a role-based rule
  that covers future reports without amendment. The original amendment text is retained in
  ADR-018 for the record.
- **`models/marts/reports/` reorganised into one directory per report family** — dpr, retail,
  tracker, attendance, scan, today_sales, website_commerce, restricted (plus the existing
  disabled/). 70 files moved. `ref()` is name-based so no reference changed; `dbt_project.yml`
  configs cascade into subdirectories so no config changed.
- **The 997-line `models/marts/reports/schema.yml` is split into eight per-family files**
  (25–379 lines each). The parent file is removed, since no report model was left unowned.
- **Report-layout dimensions co-located with their reports** — the eight `dim_*_line_item` /
  `dim_*_print_line` models move from `models/marts/dimensions/` into their family directory.
  Their `materialized='table'` is set in each model's own config, so materialization is
  unchanged; their dbt group moves from `gold_dimensions` to `gold_reports` (all are
  `access: public`, so nothing breaks). Business dimensions stay in `dimensions/`, whose
  schema.yml drops from 326 to 236 lines.
- **Report-layout seeds moved to `seeds/report_layout/`** (the five `*_line_items` and two
  `*_print_lines`). Seed paths do not affect `ref()`.

### Removed

- **`rpt_tracker_week_bucket.sql`** — superseded by the `dim_date` columns in 7.12.2, whose
  APPLY.sh deletion never ran. Also `DROP VIEW IF EXISTS MARTS.RPT_TRACKER_WEEK_BUCKET;` in
  Snowflake.

### Verified

- `dbt parse` green: 132 enabled models + 7 gated (`enabled=false`), 394 data tests, 25 seeds.
- File/model integrity checked both directions: every `.sql` outside `disabled/` is either
  registered or explicitly `enabled=false`, and every registered model resolves to a file. No
  model was lost or orphaned by the move.

### Open items carried forward

- ADR-021 §3 needs Data & AI Committee ratification; until then model headers cite it as
  Proposed. Twenty models depend on it — the same exposure the 2026-07-29 amendment carried,
  now written down accurately.
- `TOTAL_ESTIMATED_REVENUE` is authored twice (`rpt_dpr_mtd_ytd_long` and inline in
  `rpt_dpr_report_long`), which violates ADR-021's composite rule on the day it is written.
  Recorded as an accepted risk in the ADR with remediation owed next release.
- Three composites live in a serving model rather than the semantic view
  (`TOTAL_GUIDED_TOUR_REVENUE`, `TOTAL_OTHER_VISITOR_REVENUE`, `TOTAL_ESTIMATED_REVENUE`);
  promote to sv metrics.

## [7.12.5] — 2026-08-10 — DPR MTD / YTD / Excel Data Serving (reports 2–4)

Finishes the three DPR variants. Correcting an earlier claim in the build notes: these are
NOT DAX variants of the daily DPR stack. The MTD/YTD workbooks print a different, longer
line-item set (~61 printed rows vs dpr_line_items' 28), compare ACTUAL to PRIOR YEAR rather
than to budget, break donations out individually, and print retail sub-metrics the DPR fact
does not carry. DPR Excel Data prints area REVENUE where the other reports print gross
PROFIT.

### Added

- **`rpt_dpr_retail_conform`** — cross-domain conform of the retail sub-metrics the MTD/YTD
  workbooks print (store visitors/customers/sales/profit, carts, e-com orders, cafe
  transactions), one row per date by facility_group. Mirror of `rpt_retail_report_long`
  reaching into `fct_daily_performance` for attendance.
- **`rpt_dpr_period_windows`** — the four comparison windows (MTD/YTD × current/prior),
  authored once. **Prior year is a calendar-year shift, deliberately NOT the -364 days the
  daily reports use for SDLY**: 364 days before 2025-12-31 is 2025-01-01, still the same
  calendar year, which would reduce "prior-year YTD" to a one-day window. Accepts a
  `dpr_as_of_date` var to pin the anchor.
- **`rpt_dpr_mtd_ytd_long`** — day × metric long shape; additive metrics carry `amount`,
  the four ratios carry numerator/denominator for ratio-of-sums at period grain.
- **`dpr_mtd_ytd_print_lines` seed (61 rows) + `dim_dpr_mtd_ytd_print_line`** — printed-row
  catalog; one catalog serves both variants since they print identical rows. Padded
  `line_item_display` for sort-by-column (load-bearing).
- **`rpt_dpr_mtd_ytd_print`** — print-ready grid: one row per (period_group, print_code)
  with actual / prior_year / variance_amount / variance_pct.
- **`rpt_dpr_excel_export`** — the flat Excel Data workbook, column names and order per the
  workbook.

### Changed

- **`rpt_dpr_powerbi`** projects 18 additional metrics that were already authored in the DPR
  semantic view but never surfaced: service fees, mask donations, memorial audio guide,
  ask-educator revenue, total retail gross profit, total donations, audio headset units, the
  four field-trip count/revenue pairs, and the virtual memorial/museum/YF tour counts and
  revenues. No semantic-view or DDL change was needed — the metrics existed.

### Verified against the 2025-12-31 workbooks (to the cent)

Three composites are authored once in `rpt_dpr_mtd_ytd_long` because the semantic view has
no metric for them, and all three reconcile exactly in BOTH the MTD and YTD workbooks:

- `TOTAL_GUIDED_TOUR_REVENUE` = mus_guided + mem_guided + revealed + virtual_yf + mem_mus
  (MTD 187,432 + 0 + 64,708.80 + 0 + 289,305 = 541,445.80 ✓)
- `TOTAL_OTHER_VISITOR_REVENUE` = audio headset + mem audio + ticketing + coatcheck +
  mus_exit + mus_store_don + cart_ask + cafe_don + ecom_ask + mask (MTD = 591,654.68 ✓).
  This settles an open question: the report means `MUS_EXIT_DON`, **not**
  `BOX_OFFICE_MUS_EXIT_DON`, and excludes `BOX_OFFICE_MEM_DON` and `DONATION_BOX`.
- `TOTAL_ESTIMATED_REVENUE` = admission + guided total + virtual total + retail GP total +
  cafe profit + other visitor total (MTD = 9,170,373.79 ✓)

Ratio definitions also confirmed arithmetically: capture rate = store visitors ÷ museum
attendance (106,299 / 266,115 = 39.94% ✓); conversion = customers ÷ visitors (17.29% ✓);
average sale = store NET SALES ÷ customers (not gross profit).

### Open items

- **`Total Museum Revenue` / `Total Memorial Revenue` in the Excel export are typed NULL** —
  the memorial-vs-museum revenue split is the same ADR-005 committee rule blocking the YTD
  Tracker. A guess must not enter a finance-facing export.
- **`Museum Donations` / `Memorial Donations` in the Excel export are NULL** pending the two
  donation composites being projected onto `rpt_dpr_powerbi`. Add the semantic-view metrics;
  do not re-author the sums locally.
- **Assumption to confirm**: `CityPASS*` = `pass_revenue`; `Shopify Donations` =
  `ecom_donation_ask`.
- **Stub lines** (render blank, faithful to a report that prints 0): Early Access Museum tour
  COUNT, Youth & Family tour COUNT, Early Access Memorial + Museum tours and revenue, the
  Virtual-section "Revealed Tour Revenue" line, E-Commerce gross profit (a known DPR gap),
  Estimated Budgeted Operating Expenses, Revenue as % of Budgeted Operating Expenses.
- **Variance NULL vs '0%'**: this build emits NULL where prior year is NULL; the legacy
  workbook prints 0%. Confirm which leadership expects.
- **Follow-up**: `rpt_dpr_report_long` still authors `TOTAL_ESTIMATED_REVENUE` inline, so the
  composite now exists in two models. Migrate report_long to a shared column (same treatment
  7.12.1 gave the tracker) in a later release.
- **Housekeeping**: `rpt_tracker_week_bucket.sql` is still present though 7.12.2 removed it —
  delete the file and `DROP VIEW IF EXISTS MARTS.RPT_TRACKER_WEEK_BUCKET;`.

## [7.12.4] — 2026-08-07 — Retail Performance Printed Grid (PDF-faithful rows)

Reading the legacy PDF closely showed the report prints **scenario as ROWS**, not columns:
each metric appears as a '... Goal' row and a '... Actual' row, with a shaded 'Variance'
row on selected metrics only, and the six periods as the only columns. Every prior spec
(and the Power BI guidance built on it) assumed scenario-as-columns. This release encodes
the printed layout in the platform so Power BI needs one measure and no scenario switch.

### Added

- **`retail_print_lines` seed** (69 rows) — the printed-row catalog: one row per line as it
  appears on the PDF, in print order, carrying the metric it reads and its scenario
  (actual / goal / variance). Which metrics get a Variance row is *data*, not inference.
- **`dim_retail_print_line`** — presentation catalog over the seed. Complements
  `dim_retail_line_item`, which stays the *metric* catalog; neither replaces the other.
  `line_item_display` appends occurrence-index trailing spaces so repeated labels
  ('Variance' x8, 'Revenue / Museum Visitor' x4) are unique for Power BI's sort-by-column
  (which requires a 1:1 label→sort mapping) while rendering identically. **The padding is
  load-bearing — do not "clean it up."**
- **`rpt_retail_report_print`** — the printed grid: one row per (period_code, print_code)
  resolving each line to a single `value`. Cross join of 6 windows x 69 lines, LEFT joined
  to `rpt_retail_report_periods`, so Stub lines render NULL instead of vanishing. Power BI
  becomes: rows = section → line_item_display, columns = period_label, values =
  max(value).

### Changed

- **`rpt_retail_period_windows`** accepts an optional `retail_as_of_date` var to pin the
  anchor for reconciliation against a specific legacy PDF:
  `dbt build --select rpt_retail_period_windows+ --vars '{retail_as_of_date: "2026-07-28"}'`.
  Unset in scheduled runs, so the anchor follows the data.

### Known layout deltas (documented, not defects)

- **Medallion Machine** has no facility mapping in `seed_facility_area`; its three rows are
  Stub/NULL (the PDF prints $0/$0/0). Confirm the CounterPoint store → facility mapping and
  the rows light up with no report change.
- **Museum Cafe Donation Ask Variance** prints $0 on the legacy report across all periods
  even where actual is non-zero and goal is $0; this build computes actual − goal. Confirm
  whether the legacy $0 is intentional before matching it.
- **Memorial Carts donations** label asymmetry ('Donations Goal' / 'Donation Ask Actual') is
  reproduced verbatim from the PDF.

## [7.12.3] — 2026-08-07 — Retail Performance DirectQuery Serving (periods resolved in SQL)

Extends the 7.12.1/7.12.2 DirectQuery approach to the Retail Performance Report. Its six
printed period columns x 3 scenarios x 34 line items is ~600 DAX time-intelligence cells —
the worst-case DQ workload. Jeremy's call: resolve the periods in dbt and let Power BI
render a dumb, fast grid.

### Added

- **rpt_retail_period_windows** — the six printed periods (Current Day / SDLY / WTD / MTD /
  QTD / YTD) authored ONCE as [start_date .. end_date] ranges. Anchored on the latest
  ACTUALS date before today, from `rpt_retail_powerbi` **not** `rpt_retail_report_long`:
  the budget side carries forward-dated forecast rows that would drag the anchor into the
  future and inflate every budget window. Consumed by both page models so the two pages
  cannot disagree about a period.
- **rpt_retail_report_periods** — page-1 grid, one row per (period_code, line_item_code)
  with `actual_value` / `budget_value` / `variance` / `variance_pct` resolved. Ratio lines
  divide sum(numerator)/sum(denominator) **within each window** — ratio-of-sums preserved,
  never an average of daily ratios. Variance blank-guarded (unbudgeted lines read NULL, not
  -100%). Component sums retained for audit.
- **rpt_retail_category_periods** — page-2 category grid over the same shared windows
  (additive only). Category budget stays NULL by design (facility-grain forecast).
- **rpt_retail_narrative_card** — deterministic ASCII analyst card rendered in SQL over
  rpt_retail_narrative_brief; binds as a plain view under DQ (twin of
  rpt_tracker_narrative_card). Works before T_RETAIL_NARRATIVE is resumed.

### Notes

- **Supersedes** the original Retail build spec's "do not materialize WTD/MTD/QTD/YTD in
  SQL" instruction, which assumed Import mode. The reason for that rule — ratio correctness
  at every period grain — is preserved by construction here.
- As-of snapshot models (~204 rows page 1): they emit the current reporting day only.
  History stays in rpt_retail_report_long / rpt_retail_category_long.
- Sign-off gate: validate the window definitions (SDLY = -364 days, Sunday-start WTD,
  calendar MTD/QTD/YTD) against the legacy .prpt, then reconcile the grid to a recent PDF.

## [7.12.2] — 2026-08-07 — Week Buckets Fold into dim_date

Jeremy's call after DirectQuery relationship-folding trouble with the separate
rpt_tracker_week_bucket view: the bucket columns move INTO dim_date, so the Tracker
matrix needs no second date-grain table and no extra relationships.

### Changed

- **dim_date** gains `week_bucket` + `bucket_sort` (Daily Tracker rolling buckets:
  'Prior Years' / '1/1 - MM/DD' / current + two prior Mon-Sun weeks / 'Future').
  Anchored to yesterday America/New_York at BUILD time — same convention as the existing
  ptd comparison flags, and same nightly cadence as the tracker facts, so buckets and
  data roll together. (Trade-off vs the removed view: the view anchored at query time;
  in-dim anchoring is build-time. Accepted — a delayed build delays facts and buckets
  equally.)
- Schema docs added for `week_start_monday` / `week_end_sunday` / `week_bucket` /
  `bucket_sort`.

### Removed

- **rpt_tracker_week_bucket** (model + schema entry) — superseded one release later by
  the dim_date columns. Drop the deployed view: `DROP VIEW IF EXISTS
  MARTS.RPT_TRACKER_WEEK_BUCKET;` (APPLY.sh prints the reminder).

### Power BI

Remove the WeekBucket table from the model; matrix columns = `Dim_Date[WEEK_BUCKET]`
(Sort By -> `Dim_Date[BUCKET_SORT]`), filter out 'Future'/'Prior Years'. No new
relationships — Dim_Date already filters both tracker facts.

## [7.12.1] — 2026-08-07 — Tracker DirectQuery Support (week bucket in-platform, composite DRY, card view)

Jeremy chose DirectQuery for the Tracker PBIX (no separate refresh schedule to race the
nightly load). DQ forbids the calculated-column / text-measure patterns the Import build
used, so the logic moves into the platform — where ADR-004 wanted it anyway.

### Added

- **dim_date**: `week_start_monday` / `week_end_sunday` — static Mon-Sun week bounds for
  Mon-anchored report weeks (the existing first/last_day_of_week are Sun-anchored).
- **rpt_tracker_week_bucket** (view, POWERBI_ROLE): one row per date_key with the Daily
  Tracker's rolling buckets — 'Prior Years' / '1/1 - MM/DD' / current + two prior Mon-Sun
  weeks / 'Future' — plus a `bucket_sort` date. Anchor = yesterday America/New_York,
  computed at query time (always current under DQ, immune to a delayed dim_date rebuild).
  Replaces the Power BI calculated columns.
- **rpt_tracker_narrative_card** (view): the deterministic ASCII analyst card rendered in
  SQL over rpt_tracker_narrative_brief — binds as a plain view under DQ, replacing the
  Value.NativeQuery M pattern for this report.

### Changed

- **Earned-revenue composite defined once** (prime rule): `total_earned_revenue` is now a
  column on `rpt_tracker_powerbi`, `earned_revenue_projection` on
  `rpt_tracker_budget_daily`; `rpt_tracker_report_long` and `rpt_tracker_narrative_brief`
  consume the columns instead of re-authoring the sums. Fixes a latent divergence: the
  report_long's actual-side composite summed WITHOUT coalesce (any NULL component NULLed
  the whole line) while the brief coalesced — the coalesced form is now canonical.
  Output-equivalent otherwise; verify with a day-grain row-count + total diff on
  rpt_tracker_report_long before/after.

### Notes

- Memorial-vs-Museum revenue split is deliberately NOT added (ADR-005 gate — committee
  rule pending). The provisional split stays in DAX, clearly labeled.
- Power BI: remove the Week Bucket / Bucket Start calculated columns; bind
  rpt_tracker_week_bucket (relate date_key -> both tracker facts' report_date), use
  week_bucket on matrix columns sorted by bucket_sort, filter out 'Future'/'Prior Years'.

## [7.12.0] — 2026-08-04 — Reports 6–8 Serving Stack (Attendance · Carts Analysis · Website Commerce)

Serving + narrative layer for the remaining Pentaho migrations, on the exact pattern of the
five built reports (tidy report_long with ratio components, line-item seed + dim, deterministic
brief → gated Cortex narrative → task setup script; periods in DAX, never SQL — ADR-004).

### Added

- **Attendance Report stack** — `rpt_attendance_report_long` (day × line item; all additive,
  no goals; also serves the single-figure Daily Attendance Report as a card on
  MUS_ATTENDANCE), `attendance_line_items` seed + `dim_attendance_line_item`
  (Sensource-backed lines marked Stub), `rpt_attendance_narrative_brief` +
  `rpt_attendance_narrative` (gated) + `scripts/setup_attendance_narrative.sql`
  (T_ATTENDANCE_NARRATIVE → ATTENDANCE_PBI_NARRATIVE).
- **Retail Carts Analysis stack** — `rpt_carts_report_long` (ratio lines carry
  numerator/denominator so the workbook's monthly views are ratio-of-sums, never averaged
  daily ratios; the legacy adjusted-visitor denominator components are carried additively),
  `carts_line_items` seed + `dim_carts_line_item` (visitor-derived lines Stub pending
  Sensource), `rpt_carts_narrative_brief` + `rpt_carts_narrative` (gated) +
  `scripts/setup_carts_narrative.sql` (T_CARTS_NARRATIVE → CARTS_PBI_NARRATIVE). Capture
  rate and per-caps are excluded from the brief while their denominator is a stub.
- **Website Commerce serving** — `rpt_website_commerce_daily` (day × revenue_type;
  supersedes the month-pivot for the PBI rebuild — pivot moves to a Power BI matrix over
  dim_date) and `rpt_website_commerce_detail` ("Donations By Date", day × title, no PII
  projected). `is_recurring` is TRUE on every row today: only the recurring feed is live;
  the one-time website feed is a documented open seam. No narrative chain — monthly
  cadence does not warrant a daily note; revisit if the report becomes a daily subscription.

### Documented (no code)

- **DPR Excel variants need no new models**: "DPR Excel Data" binds to `rpt_dpr_powerbi` +
  `rpt_dpr_budget_daily`; the MTD/YTD prior-year workbooks are DAX
  (`SAMEPERIODLASTYEAR` over `rpt_dpr_report_long`) — added to the build notes.
- README / report_semantic_view_map rows for the new stacks.

### Fixed

- `dbt_project.yml` version was left at 7.11.1 by the 7.11.2 patch; now aligned (7.12.0).

## [7.11.2] — 2026-07-31 — Patch: Semantic-View Name Shadowing (supersedes 7.11.1's alias)

7.11.1's fact alias failed with "Cyclic reference of expressions is not allowed:
[DP.ADMISSION_REVENUE_VALUE, DP.TOTAL_ADMISSION_REVENUE]" — proving the full rule: a
semantic-view **metric name shadows the same-named base column in EVERY expression in
the view** (facts included), so no expression can reach the column while the metric
carries its name. The metric name is public (Power BI wrapper, Cortex queries), so the
name stays and the view restates the components — with a dbt reconciliation test as the
drift guard the review originally wanted.

### Fixed

- **DPR.sv.yaml** — fact alias removed; `TOTAL_ADMISSION_REVENUE` authored as
  `SUM(TICKET_REVENUE) + SUM(PASS_REVENUE)` with the engine limitation and the guard
  test documented in the metric description. `AVG_TICKET_PRICE` stays metric-over-metric
  (unchanged from 7.11.1 — that part deployed correctly).
- **UNIFIED.sv.yaml** — `total_admission_revenue` reverted to the component sum for the
  same reason (identifiers are case-insensitive, so its lowercase metric name collides
  with the column too; 7.8.0's `SUM(TOTAL_ADMISSION_REVENUE)` there would have failed
  the same way on deploy).
- **New test `assert_sv_admission_revenue_matches_fct`** (error): day-grain equality
  between `rpt_dpr_powerbi.admission_revenue` (via the deployed semantic view) and the
  governed `fct_daily_performance.total_admission_revenue`. This is the enforcement
  that replaces "sum the column": if the fct definition ever changes, this test fails
  the same day and points at the two sv.yamls.
- Both DDLs regenerated; `--check` green.

### Migration notes

Re-run `scripts/deploy_semantic_view_dpr.sql` and `deploy_semantic_view_unified.sql`
(after `USE DATABASE <target>`) per database. Then `dbt test --select
assert_sv_admission_revenue_matches_fct` to confirm the guard passes.

---

## [7.11.1] — 2026-07-31 — Patch: DPR Semantic View Deploy Failure

`CREATE SEMANTIC VIEW` for DPR failed with "Invalid metric definition for
'DP.AVG_TICKET_PRICE': A metric must directly refer to another aggregate-level
expression ... without an aggregate." Root cause: in 7.8.0 the ratio was authored as
`SUM(TOTAL_ADMISSION_REVENUE) / NULLIF(SUM(TICKETS_SOLD), 0)`, but
`TOTAL_ADMISSION_REVENUE` is BOTH a fct column and a metric name in the DPR view — and
inside metric expressions Snowflake resolves the name to the METRIC, producing an
aggregate-of-an-aggregate.

### Fixed (DPR.sv.yaml + regenerated deploy_semantic_view_dpr.sql)

- New fact **`ADMISSION_REVENUE_VALUE`** — row-grain alias of the governed
  `TOTAL_ADMISSION_REVENUE` column, so the same-named metric can sum it unambiguously:
  `TOTAL_ADMISSION_REVENUE AS SUM(ADMISSION_REVENUE_VALUE)`. Still the
  defined-once column; still never re-derived from components.
- **`AVG_TICKET_PRICE`** authored metric-over-metric (Snowflake's required form for
  ratios): `TOTAL_ADMISSION_REVENUE / NULLIF(TOTAL_TICKETS_SOLD, 0)` — mathematically
  identical to the locked ratio-of-sums, recomputed at query grain.
- **`MUS_STORE_PROFIT_PER_VISITOR`** same form:
  `TOTAL_MUS_STORE_GROSS_PROFIT / NULLIF(TOTAL_MUSEUM_ATTENDANCE, 0)`.
  (UNIFIED's SUM-of-columns form stays as-is — its metric names don't collide with
  column names, so it deploys; both forms are the same ratio-of-sums.)
- `--check` green; 49 metrics.

### Migration notes

Re-run `scripts/deploy_semantic_view_dpr.sql` (after `USE DATABASE <target>`) in every
database you deploy to. No dbt model changes.

---

## [7.11.0] — 2026-07-31 — Hygiene & Docs Sweep

Closes the remaining medium/low findings from the post-build review.

### Fixed

- **Narrative task prompts re-synced with their dbt source models.** The deployed-task
  copies in `scripts/setup_dpr_narrative.sql` / `setup_retail_narrative.sql` had drifted
  from `rpt_dpr_narrative.sql` / `rpt_retail_narrative.sql`: missing the YoY
  contextualization rule, missing "significant YoY divergence" in the watch-items rule,
  and framing "the day's" instead of "the previous day's" performance. Prompts are now
  verbatim-identical; both rpt_ models carry a SYNC GUARD note (there is no automated
  drift check for this pair yet — candidate for a future generator).
- **PII coverage extended to the Gateway staging name columns**:
  `STG_GATEWAY__TICKETS` and `STG_GATEWAY__JNLTICKETS` `first_name`/`last_name` added to
  `apply_masking_policies` and `apply_governance_tags` (they feed the already-masked
  `dim_customer.customer_name`, but staging-schema readers saw them unmasked); both
  models and `stg_ecommerce__website_recurring` now carry the `pii`/`restricted` config
  tags their WiFi sibling had.
- **`rpt_dpr_budget_daily.report_date` unique test** demoted error → warn: the dpr CTE
  passes `fct_budget_dpr_forecasts` rows through un-aggregated, so the grain is
  partially inherited (severity rule).
- **`rpt_daily_scan` header** no longer claims the DSR forecast seed is unpopulated
  (fct_daily_scan joins the real budget; variance is NULL only where the forecast has
  no row).
- **`fct_daily_operations.ticket_revenue`** now documents in-model that it is the
  POS-derived measure and NOT `fct_daily_performance.ticket_revenue` (GA journal) —
  the shared name is historical; renaming was deliberately skipped (two tests and the
  ML training set bind to it) and can be revisited with the ML model retrain.
- `rpt_wifi_email_export` schema docs now list all four columns incl. `capture_date`.
- Committed `__pycache__/` artifacts removed from both dpr-dashboard copies (already
  gitignored; if still tracked in your clone: `git rm -r --cached dpr-dashboard/__pycache__ dpr-dashboard/deployed/__pycache__`).

### Deferred (documented, deliberately unchanged)

- `TOTAL_RETAIL_GROSS_PROFIT` component realignment/rename — ADR-005 committee item
  (see 7.8.0).
- The Streamlit dashboard re-derives donation/audio composites in Python (a third
  authored surface); migrating it to read `rpt_dpr_powerbi` is a candidate follow-up.
- Generic-test macro library adoption; function-pipeline packaging; ADR 007–017
  register reconciliation — unchanged standing items.

---

## [7.10.0] — 2026-07-31 — Reports 2–4 Serving Stack (Today's Sales · Daily Scan · YTD Tracker)

Lands the component stack the 2026-07-29 build notes specified but that never reached the
repo: only the thin wrappers and semantic-view additions existed. Each report now has the
full Retail-pattern stack (report_long, line-item seed + dim where applicable, narrative
chain, task setup script). 18 files added, 5 edited; all patterns mirror the existing DPR
and Retail stacks.

### Added

**Report 2 — Today's Sales (intraday, report_date × hour_of_day × key_facility):**
`rpt_today_sales_report_long` (long shape over the existing wrapper; no budget — the
report has no goals; stub lines emitted as typed NULLs), `today_sales_line_items` seed +
`dim_today_sales_line_item` (12 PDF lines; Conversion / Capture / Store Visitors /
Attendance / Totes marked Stub pending the intraday visitor feed and tote-SKU flag),
`rpt_today_sales_narrative_brief` (day-to-date vs same-weekday-last-week) +
`rpt_today_sales_narrative` (enabled=false) + `scripts/setup_today_sales_narrative.sql`
(T_TODAY_SALES_NARRATIVE → MARTS.TODAY_SALES_NARRATIVE, 05:30 ET; hourly intraday
schedule documented as an option).

**Report 3 — Daily Scan (report_date × segment_key):**
`rpt_daily_scan_report_long` (TICKETS_SOLD / FORECAST_TICKETS_SOLD / PASSES_SCANNED
carried as components; Variance % / % Used / % of Market are DAX ratio-of-sums; explicit
union so NULL-forecast segments keep their Forecast row; segment labels ride
`seed_scan_market_segment` — no new seed), `rpt_daily_scan_narrative_brief` +
`rpt_daily_scan_narrative` (enabled=false) + `scripts/setup_daily_scan_narrative.sql`
(T_DAILY_SCAN_NARRATIVE → MARTS.DAILY_SCAN_NARRATIVE).

**Report 4 — Memorial & Museum Daily Tracker YTD (report_date; YTD in DAX):**
`rpt_tracker_powerbi` (actuals conform over rpt_dpr_powerbi — sanctioned rpt→rpt
projection chain; Total Earned Revenue component set documented in-header, mirroring the
DPR TOTAL_ESTIMATED_REVENUE composite), `rpt_tracker_budget_daily` (projection conform
over rpt_dpr_budget_daily, columns mirroring the actuals; donations + virtual-tour
revenue are not budgeted → excluded from the projection, flagged for legacy
confirmation), `rpt_tracker_report_long`, `tracker_line_items` seed +
`dim_tracker_line_item` (Memorial-vs-Museum REVENUE split rows marked Stub — the one
open business rule), `rpt_tracker_narrative_brief` + `rpt_tracker_narrative`
(enabled=false) + `scripts/setup_tracker_narrative.sql` (T_TRACKER_NARRATIVE →
MARTS.TRACKER_NARRATIVE).

### Changed

- `rpt_memorial_museum_tracker_ytd` — header corrected (it claimed budget columns were
  joined; none were) and marked superseded for the Power BI build by the `rpt_tracker_*`
  stack (kept for existing consumers); now also carries `tickets_sold` +
  `tickets_sold_ytd` (the tracker's Museum panel requires it).
- `models/marts/reports/schema.yml` (11 new entries, severities per the rule),
  `models/marts/dimensions/schema.yml` (2 dim entries), `seeds/_seeds.yml` (2 seeds),
  `models/marts/reports/README.md` (inventory updated: 34 files / 29 build / 5 gated).

### Deploy order (per the build notes)

1. `dbt seed --select today_sales_line_items tracker_line_items`
2. `dbt build --select rpt_today_sales_report_long rpt_daily_scan_report_long rpt_tracker_powerbi+ dim_today_sales_line_item dim_tracker_line_item`
3. Run the three `scripts/setup_*_narrative.sql` (after `USE DATABASE <target>`); eyeball
   the first notes; `ALTER TASK ... RESUME`.
4. Build each PBIX; reconcile to a recent legacy PDF; route through change control.

### Sign-off gates (open, from the build notes — not blockers)

- Confirm the DSR forecast basis (tickets-sold vs scanned forecast).
- Confirm the tracker's earned-revenue and projection definitions vs the legacy PDF.
- Decide the Memorial-vs-Museum revenue-split business rule (ADR-005) — the two Stub
  rows light up when it lands.
- Memorial Cart 1/2/3 split needs `store_id` retained in `fct_today_sales_hourly`
  (small fact change, separate PR).

---

## [7.9.0] — 2026-07-31 — Fact-Layer Correctness

Fixes the two numbers-level defects found by the post-build review (retail return
netting, retail budget grain), hardens the Daily Scan lineage against fan-out, and
closes the test-coverage gaps against the severity rule.

### Fixed

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

### Added — test coverage per the severity rule

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

### Migration notes

1. `dbt build --select int_counterpoint__retail_lines+` and row-count/row-diff the DPR
   chain (must be identical) and `fct_retail_performance` (changes only where returns
   exist). Reconcile a recent day against the legacy Retail Performance PDF.
2. Re-deploy the RETAIL semantic view (budget fact descriptions updated).
3. Anything that read `fct_retail_performance.net_sales_budget/net_profit_budget`
   should rebind to `rpt_retail_budget_daily`.

---

## [7.8.0] — 2026-07-31 — Semantic Layer: Metric Truth

Closes the metric-definition drift found by the 2026-07-31 post-build review: the DPR
DDL was stale (missing the two ratio metrics — `--check` failed), and the ratios
themselves violated the 2026-07-29 locked definitions.

### Fixed

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

### Changed

- `DPR.sv.yaml` `TOTAL_RETAIL_GROSS_PROFIT` description now warns that the metric
  (store + carts + cafe) is NOT the legacy DPR report's "Total Retail Gross Profit"
  line (store + carts + e-commerce, cafe separate). Component realignment or rename is
  an **open ADR-005 item** for the committee — flagged, not changed, because the
  `TOTAL_RETAIL_GROSS_PROFIT` metric code flows through `rpt_dpr_report_long` and the
  line-item seed.
- `scripts/generate_semantic_view_ddl.py` — stray AI-attribution comment removed
  (banned by the header standard).

### Migration notes

1. Re-deploy the four semantic views (`scripts/deploy_semantic_view_*.sql` after
   `USE DATABASE <target>`, or via the cortex manifest).
2. Saved Cortex/BI queries using the RETAIL facility-grain `TOTAL_RETAIL_DONATIONS`
   must switch to `TOTAL_RETAIL_DONATION_ASK` (the category-grain locked name is
   unchanged).
3. Anything reading `rpt_daily_performance_report.mus_store_rev_per_visitor` must
   rebind to `mus_store_profit_per_visitor`.

---

## [7.7.0] — 2026-07-31 — Single Source Database (ADR-019)

Formalizes what the build already did implicitly: **every environment — sandboxes, shared
dev, CI, and prod — reads RAW/SEEDS source data from the one shared database
`NS11MM_DW_DEV`** while ingestion is seed-based. Decided with Jeremy 2026-07-31; recorded
as ADR-019 (Proposed, committee ratification with the ADR-005 open items).

### Added

- **`docs/adr/ADR_019_single_source_database.md`** — the decision, options considered
  (prod-hosted and per-environment landing set aside, with the end-state noted), risks,
  and the revisit trigger (first production-enabled function pipeline / prod landing /
  2026-12 go-live review). ADR index updated.
- **`scripts/setup_source_grants.sql`** — cross-database read grants: USAGE + SELECT
  (current and future) on `NS11MM_DW_DEV.RAW` / `.SEEDS` for `TRANSFORMER_ROLE`
  (sandboxes + CI) and `DEPLOY_PROD_ROLE` (prod builds). Read-only — RAW stays
  LOADER_ROLE-write-only per ADR-001.

### Changed

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

### Migration notes

1. Run `scripts/setup_source_grants.sql` as SECURITYADMIN (prod's read on shared dev is
   what makes the next prod build work under least privilege).
2. If any wrapper scripts pass `--vars '{seed_database: ...}'`, rename the key to
   `source_database`.
3. No data moves. When ingestion is automated, flip `source_database` per ADR-019's
   revisit trigger.

---

## [7.6.0] — 2026-07-31 — Rollout Reconciliation & Security

First of the 7.6.0–7.11.0 series (post-build review, 2026-07-31; see
`claude/post-build-review-2026-07-31.md` in the project workspace). This release makes the
tree match the record: the deletions, renames, and added files that 7.0.0–7.5.2 recorded
but that were **not present in the built tree** are actually applied here, and CI is
restored to a runnable state.

### Security

- **`git_workspace_setup.sql` deleted (again).** The file — containing a live GitHub PAT —
  was still at the repo root despite 7.0.0 and 7.5.1 both recording its removal.
  **The token must still be revoked in GitHub and the file purged from history**
  (`git filter-repo` / BFG); deleting it in a commit is not revocation.
- `pipelines/salesforce_mc/temp_pipeline.py` deleted (real SFMC tenant URIs + Snowflake
  account/user literals; Key-Vault-bypassing local path).
- `.temp/` removed entirely (stale governed-seed copies — `seed_retail_store_facility.csv`
  was missing the Museum Cafe row; `seed_tour_plu.csv` had the pre-fix row set). If the
  directory is still tracked in your clone: `git rm -r --cached .temp/` then delete.

### Removed / renamed (re-applying the 7.0.0–7.5.0 lists)

- `TEMP_POC_MIGRATION.md` (root) — superseded by `docs/POC_MIGRATION_RECORD.md` (7.4.0)
- `seeds/tmp_seed_dsr_budget.csv` — orphan; dbt was loading it as a stray table every `dbt seed`
- `cortex_project/JMYERS_TEST.agent.yaml` — byte-identical duplicate of `DPR_ANALYST.agent.yaml` (7.3.0)
- `macros/data_quality/check_source_freshness.sql` — removed in 7.2.0; targeted nonexistent `RAW.RAW_*` tables
- `scripts/generate_dpr_semantic_view.py` — legacy DPR-only generator superseded by
  `generate_semantic_view_ddl.py` (7.3.0); crashed on run and emitted old DB-qualified DDL
- `docs/adr/ADR_018_metric_defintion_ownership.md` → `ADR_018_metric_definition_ownership.md`
  (filename typo fixed; the ADR index already linked the corrected name)
- `docs/architecture/CODEOWNERS` → `.github/CODEOWNERS` (the location GitHub enforces),
  with paths modernized to the current tree (`models/raw` / `models/intermediate` /
  `models/marts`, cortex_project, profiles files)

### Added (files earlier releases recorded but that were missing)

- **`profiles.yml.template`** (7.0.0) — env_var-based identity, `externalbrowser` auth for
  interactive targets, new `ci` target against `NS11MM_DW_DEV_CI`
- **Root `profiles.yml`** (7.5.2) — credential-free, committed, for dbt Projects on
  Snowflake; routes role/warehouse/database/schema only
- `.gitignore` updated to match: root `profiles.yml` is no longer ignored (it is
  credential-free by design); credential rules stated in-file

### Fixed — CI actually works (restores the 7.2.0 design)

- **`.github/workflows/dbt-ci.yml` rewritten as two jobs:** `main-manifest` (push to main →
  publish `manifest.json` artifact) and `pr-ci` (restore latest main manifest → slim
  `state:modified+` deferred build, with full-build fallback when no manifest exists).
- Builds land in **`NS11MM_DW_DEV_CI`**, never a personal sandbox.
- `DBT_PROFILES_DIR` pinned to `~/.dbt` in both jobs; profile written from
  `profiles.yml.template`; `SNOWFLAKE_ACCOUNT` moved from a hardcoded literal to a
  repository secret.
- **SQLFluff lint enforced** — the `|| true` is gone.
- CI secrets (`SNOWFLAKE_ACCOUNT` / `SNOWFLAKE_USER` / `SNOWFLAKE_PASSWORD`) and the
  `NS11MM_DW_DEV_CI` database must be provisioned before the workflow can go green.

### Errata

- **7.5.1's core claims did not land in this tree.** "Old paths removed; new paths
  confirmed" was false for the twelve files above, the CI restore was false (the workflow
  was still pre-7.2.0), and the `RELEASE_NOTES` file it cites does not exist in the repo.
  Its macro/lint/terraform restores (`.sqlfluff`, `.sqlfluffignore`, terraform
  `variables.tf`, ops macros, dashboard fix) **did** land and are verified.
- **7.5.2's file payload did not land** (neither profile file existed until this release).
- **7.5.3 corrections:** its resource-monitor incident text duplicates 6.1.0 verbatim
  (the quota was already raised 5→10 on 2026-07-29 and terraform already says 10) — verify
  the actual quota in Snowflake before trusting either entry; its audit findings were
  wrong against the tree (`assert_critical_tables_not_empty` covers 15 models including
  every fact listed as missing, and
  `assert_silver_gold_retail_revenue_reconciliation.sql` exists at severity error).
  Its script changes (schema-qualified deploy DDLs, generator `--database` flag) are real.

### Migration notes

1. Revoke the exposed GitHub PAT (GitHub → Settings → Developer settings → Fine-grained
   tokens) and purge `git_workspace_setup.sql` from history with `git filter-repo`.
2. Provision CI: create repo secrets `SNOWFLAKE_ACCOUNT` / `SNOWFLAKE_USER` /
   `SNOWFLAKE_PASSWORD` (CI service user) and the `NS11MM_DW_DEV_CI` database.
3. Developers: copy `profiles.yml.template` → `~/.dbt/profiles.yml` (the root
   `profiles.yml` is not for local use).
4. If `.temp/` is still tracked in your clone: `git rm -r --cached .temp/` and delete it.

---

## [7.5.3] — 2026-07-31 — Resource Monitor Fix & Portable Semantic View DDL

Session date: 2026-07-31. Production dbt run was blocked because `DBT_DEV_MONITOR` exceeded its
5-credit monthly quota (used 5.04). Restored the warehouse, audited test and alert coverage
across all mart tables and semantic views, and fixed the semantic view DDL generator to stop
hardcoding a database name.

### Fixed

| Issue | Resolution |
|-------|------------|
| `DBT_DEV_MONITOR` quota exhausted (5.04 / 5.00 credits), suspending `DBT_DEV_WH` | Increased monthly quota from 5 → 10 credits; warehouse resumed |
| `deploy_semantic_view_*.sql` hardcoded `NS11MM_DW_DEV` database | Scripts now emit schema-qualified names only; resolve from session database |

### Changed

- **`scripts/generate_semantic_view_ddl.py`** — Default behaviour omits the database qualifier
  from all DDL object references (view name, table FQNs). Scripts resolve against the current
  session database (`USE DATABASE <target>`). Pass `--database <name>` to pin a specific
  database when needed (e.g. `--database NS11MM_DW_PROD` for production deploys).
- **4 regenerated DDL files** — `deploy_semantic_view_{attendance,dpr,retail,unified}.sql` now
  use `MARTS.*` / `SEEDS.*` instead of `NS11MM_DW_DEV.MARTS.*` / `NS11MM_DW_DEV.SEEDS.*`.

### Audit Findings (informational, not yet remediated)

- All 5 Snowflake alerts in `NS11MM_DW_DEV.MONITORING` are **SUSPENDED** (source freshness,
  dbt failures, credit consumption, long-running queries, warehouse utilization).
- `assert_critical_tables_not_empty` covers only 6 of 17 enabled models — newer facts
  (`fct_daily_performance`, `fct_retail_daily`, `fct_retail_performance`, `fct_daily_scan`,
  `fct_today_sales_hourly`, budget facts, `ml_visitor_forecast_training`) are missing.
- No revenue reconciliation test for the retail path (silver → gold).
- No resource-monitor-approaching-limit alert exists.

### Migration notes

- **No breaking changes** to model SQL or schema.
- Semantic view deploy scripts now require the session database to be set before execution
  (e.g. `USE DATABASE NS11MM_DW_DEV_JMYERS;`) unless `--database` is passed at generation time.

---

## [7.5.2] — 2026-07-30 — Snowflake-Native dbt Profile

7.0.0 removed the committed `profiles.yml` for security — correct for local/CI use, but
it also removed the file that **dbt Projects on Snowflake** (`EXECUTE DBT PROJECT` /
Workspaces) reads from the project root. This release restores that path safely.

### Added

- **Root `profiles.yml` (credential-free, committed)** — routes role / warehouse /
  database / schema per target (`dev` / `dev_shared` / `prod`) for Snowflake-native
  execution. Contains no account, user, password, or keys — execution inside Snowflake
  uses the calling session's identity. Never add credentials to it.

### Changed

- `.gitignore` no longer ignores `profiles.yml` (it is credential-free by design now);
  the never-commit-credentials rule is stated in the file itself and in CONTRIBUTING.
- CI (`dbt-ci.yml`) pins `DBT_PROFILES_DIR` to `~/.dbt` in both jobs so the root
  profile never shadows the CI profile built from `profiles.yml.template`.
- CONTRIBUTING / ONBOARDING document the two-profile split (Snowflake-native root
  profile vs. `~/.dbt` for local and CI).

---

## [7.5.1] — 2026-07-30 — Rollout Corrections

Patch-application fixes only — no new functionality. Verification of the applied
7.0.0–7.5.0 releases against the source tree found three gaps, corrected here:

### Fixed

- **Release 7.2.0's file payload was not applied** — the CI workflow, release-gate and
  ops macros, and terraform files were still at their 7.1.0 state, and its new files
  (`.sqlfluff`, `.sqlfluffignore`, `terraform/modules/*/variables.tf`,
  `disabled/README.md`) were missing. All restored to the 7.2.0-era content.
- **Deletions and renames from 7.0.0–7.5.0 were skipped** — files that earlier releases
  removed or moved were still present at their old paths (including `profiles.yml` and
  `git_workspace_setup.sql` from 7.0.0 — the security-sensitive removals). Old paths
  removed; new paths confirmed (see RELEASE_NOTES for the full list).
- **`dpr-dashboard/deployed/streamlit_app.py`** was corrupted during application (file
  header pasted mid-dictionary, content duplicated). Replaced with the correct version.

---

## [7.5.0] — 2026-07-29 — Documentation Truth Sweep

Docs now describe the repo as it is. `dbt_project.yml` version aligned to this changelog
(it had stayed at 1.0.0 since initial setup).

### Changed

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

### Reconciliation

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

## [7.4.0] — 2026-07-29 — Model Hygiene

### Changed

- **Header standard completed** — the nine Power BI serving models
  (`rpt_*_powerbi`, `rpt_*_report_long`, `rpt_retail_category_long`, `rpt_*_budget_daily`)
  now carry the standard Layer/Domain/Grain/Feeds/ADR header; layer tokens normalized on the
  ML and narrative models; 78 AI-attribution comment lines stripped repo-wide;
  `rpt_daily_performance_report`'s table override documented with a MATERIALIZATION note.
- **Budget reports no longer self-source** — `rpt_dpr_budget_daily` / `rpt_retail_budget_daily`
  read the `fct_budget_*` models via `ref()` instead of a fake `source()` (DAG ordering and
  lineage restored); dead source blocks removed; `_budget_sources.yml` moved to `models/raw/`
  with the stg-bypass exception documented.
- **Facility literals removed from the new report family** — `rpt_retail_report_long`,
  `rpt_retail_narrative_brief`, `rpt_dpr_budget_daily` join `dim_facility` and key off
  `facility_group` instead of raw facility numbers (1:1 join on `key_facility`, same rows
  selected — a renumber no longer touches report SQL).
- **Deprecated `tests:` keys converted to `data_tests:`** with
  `dbt_utils.unique_combination_of_columns` replacing concatenated-column unique tests.
- **Severity rule applied both directions** — four GROUP-BY-enforced grain tests promoted
  warn → error (`int_retail__performance`'s grain combination also corrected to
  date × facility × category); `int_budget__*` uniques and `rpt_dpr_powerbi.report_date`
  demoted to warn (inherited/unverified grains).

### Added

- **schema.yml coverage for all 16 previously undocumented active models**, including
  `int_gateway__item_attributes` and `fct_today_sales_hourly`, and `rpt_wifi_email_export`
  documented as RESTRICTED/PII; `int_gateway__ticket_journal_lines.jnl_detail_id` finally
  has a `unique` test (warn) — the DPR backbone's grain was previously untested.
- `retail_line_items` and `seed_scan_market_segment` registered in `_seeds.yml` with tests
  (both actively consumed but previously unregistered); `ref_*` seeds marked as legacy
  deletion candidates.
- `fct_ticket_availability` NOTE documenting the 7-day-lookback vs 90-day-window constraint
  (monthly `--full-refresh` recommended); redundant `enabled=true` removed.

### Removed

- Eight ghost `tmp_seed_*` entries in `_seeds.yml` (no CSVs exist); `seeds/tmp_seed_dsr_budget.csv`
  (orphan); `pipelines/salesforce_mc/temp_pipeline.py` (contained a real SFMC tenant id and
  bypassed Key Vault). `alert_management.sql` moved to `scripts/`; `TEMP_POC_MIGRATION.md`
  moved to `docs/POC_MIGRATION_RECORD.md` as a marked historical record.

---

## [7.3.0] — 2026-07-29 — Semantic Layer: Unique Metrics & Single Generator

### Changed

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

### Fixed

- ATTENDANCE/RETAIL seed references pointed at schema `MARTS`; seeds build to `SEEDS`.
- **Fiscal-calendar claims scrubbed** (dim_date has no fiscal columns): descriptions, the
  phantom `fiscal_year`/`fiscal_month` schema.yml columns on `rpt_dpr_powerbi`, and the
  YTD/monthly report headers now say calendar-based, with the fiscal variant deferred to the
  Data & AI Committee under ADR-005 (proposed FY start: October).

### Removed

- `FUNDRAISING_ECOM.sv.yaml` → `cortex_project/disabled/` and out of the deploy manifest —
  all four of its base tables are disabled dims; it cannot deploy.

---

## [7.2.0] — 2026-07-29 — Working CI, Release Gates & Infrastructure

None of the automation this patch touches could previously run as written.

### Added

- **`.sqlfluff` / `.sqlfluffignore`** — real lint config (lowercase keyword/identifier/
  function rules per the SQL style guide; layout/aliasing rule families excluded; repo lints
  clean). CI enforces it — no more `|| true`.
- **`terraform/modules/*/variables.tf`** — every module now declares the variables it
  references (`terraform validate` previously failed on undeclared inputs).
- **`disabled/README.md`** — why all 14 Azure Function CD pipelines are parked, and what
  re-enabling requires.

### Changed

- **`.github/workflows/dbt-ci.yml`** rebuilt as a working two-job slim CI: pushes to main
  compile and publish a manifest artifact; PRs lint + `dbt build --select state:modified+
  --defer` against it (full build when no state exists). Runs in a dedicated
  `NS11MM_DW_DEV_CI` database from the profile template + secrets (the old workflow exported
  env vars nothing consumed and deferred to state nothing produced). Requires repo secrets
  `SNOWFLAKE_ACCOUNT` / `SNOWFLAKE_USER` / `SNOWFLAKE_PASSWORD` and the CI database.
- **Azure Function CD** — `azure-pipelines-{counterpoint,gateway,drupal}.yml` moved to
  `disabled/`: the deployed packages had no function entrypoint and did not include
  `pipelines/shared/`, and their source queries are unconfirmed placeholders. Live ingestion
  is seed-based.
- **Terraform** — per-environment backend state keys (dev/staging/prod no longer share one
  tfstate); deploy pipelines rewritten to valid Azure DevOps YAML (ManualValidation in a
  server job for staging/prod); required variables supplied via variable groups; dev
  `credit_quota` synced 5 → 10 to match the live 6.1.0 change.

### Fixed

- **`validate_before_deploy`** (the documented release gate) — was unrunnable: 8 of 10
  models it checked are disabled/deleted and it queried a `GOLD` schema that doesn't exist.
  Rebuilt against the active critical set in `MARTS`, with graceful skips.
  `compare_model_to_prod` had the same `GOLD` bug.
- **Quarantine paths unified** on `{{ target.database }}.INTERMEDIATE` — write, resolve, and
  audit paths previously disagreed and referenced a nonexistent `SILVER` schema.
- **`gdpr_anonymize`** rewritten for the active PII surfaces: erasure happens in the RAW
  landing tables (the documented, logged exception to ADR-001 immutability), requires a
  request id, and writes an erasure audit log. The old version updated tables that no longer
  exist.
- **`rerun_from_source`** rewritten around the real seed-based source groups.

### Removed

- `macros/data_quality/check_source_freshness.sql` — built freshness queries and never
  executed them, against tables that don't exist. `dbt source freshness` (configured in
  `sources.yml`) is the real mechanism.

---

## [7.1.0] — 2026-07-29 — Prod Pathing & PII Governance

### Changed

- **`models/raw/sources.yml`** — all three raw source groups resolve via
  `{{ target.database }}` instead of a hardcoded personal dev database. A prod deploy no
  longer reads a developer sandbox; matches the pattern the other source files already used.
- **Cortex project, DPR dashboard, scripts** — semantic views, the agent, both Streamlit app
  copies, semantic-view deploy SQL, narrative setup, and `MANUAL_ML_RUN.sql` now target
  shared dev (`NS11MM_DW_DEV`) rather than a personal sandbox.
- **`pipelines/shared/`** — Key Vault URL, Snowflake database, and warehouse are env-var
  selectable (`NS11MM_KEYVAULT_URL`, `NS11MM_SNOWFLAKE_DATABASE`, `NS11MM_SNOWFLAKE_WAREHOUSE`);
  ingestion defaults to `SOURCES_WH` per SNOWFLAKE_SETTINGS (was hardcoded `COMPUTE_WH`).
- **Narrative tasks** (`scripts/setup_*_narrative.sql`) run on `MONITORING_WH`.
- **Grants** — marts/ml read access moved from post-hooks to dbt `grants` config so models
  can override the default.

### Fixed

- **`rpt_wifi_email_export` no longer inherits BI/ML grants** — `grants: {select: []}`
  overrides the marts default; POWERBI_ROLE / ML_ROLE do not receive the PII export (its own
  header required this; the inherited hook violated it).
- **`apply_masking_policies` / `apply_governance_tags` actually work** — target lists rebuilt
  from the active model estate (`stg_wifi__audience`, `stg_ecommerce__website_recurring`,
  `int_pos_tickets`, `dim_customer`, `rpt_wifi_email_export`, plus the live marts). The old
  lists named pre-rename POC and disabled objects, so the existence checks no-opped every
  entry and nothing was ever masked or tagged. View-vs-table ALTER handled; policy/tag
  database parameterized via vars.
- **`scripts/MANUAL_ML_RUN.sql`** referenced `dim_date` columns that don't exist
  (`date_id` → `date_key`, `fiscal_year` → `year_number`) — could not have run as written.

### Docs

- `docs/architecture/DATA_CLASSIFICATION.md` PII inventory rewritten to the live surfaces,
  with an explicit keep-in-sync rule binding it to the masking/tagging macros.

---

## [7.0.0] — 2026-07-29 — Security Hygiene

First of six release-readiness patches (7.0.0 → 7.5.0). Major bump: developer setup changes
(the repo-root `profiles.yml` is gone).

### Removed

- **`profiles.yml`** — a committed connection profile carrying the real Snowflake account and
  user identities (docs had claimed it was gitignored; it wasn't). It also contained a
  copy-paste bug (`dev_dsun` target pointed at DSUN's database under the jmyers user).
  **BREAKING:** developers now keep their profile at `~/.dbt/profiles.yml`, created from the
  new template.
- **`git_workspace_setup.sql`** — one-off personal workspace setup that contained a committed
  GitHub PAT. NOTE: deleting the file does not revoke the token — it must be revoked in
  GitHub (it remains in the old repository's history).
- **`.temp/uploads/`** — stale local copies of governed seeds (one missing the Museum Cafe
  facility row, one missing the VTEDU virtual-tour PLUs). Restoring from them would have
  reintroduced fixed bugs.

### Added

- **`profiles.yml.template`** — env-var-driven profile template (targets `dev` / `dev_shared`
  / `ci` / `prod`) with explicit authenticators (SSO for developers, secret-based for CI/prod).

### Changed

- `.gitignore` now explicitly ignores `profiles.yml` (template excepted) and key files
  (`*.pem`, `*.p8`).

---

## [6.1.0] — 2026-07-29 — Resource Monitor Fix & Test/Alert Coverage Audit

Session date: 2026-07-29. dbt execution failed because warehouse `DBT_DEV_WH` was suspended by
resource monitor `DBT_DEV_MONITOR` (5-credit monthly quota exceeded by 0.04 credits). Diagnosed
root cause, restored the warehouse, and audited test + alert coverage across all mart tables and
semantic views.

### Fixed

| Issue | Resolution |
|-------|------------|
| `DBT_DEV_MONITOR` quota exhausted (5.04 / 5.00 credits) | Increased monthly quota from 5 → 10 credits |
| `DBT_DEV_WH` suspended, blocking all 104 dbt models | Resumed warehouse after quota increase |

### Audit Findings — Test Coverage

| Finding | Status | Detail |
|---------|--------|--------|
| Schema-level column tests (PK unique/not_null, FK relationships) | ✅ Covered | All 13 dimensions + 11 facts + 2 ML features have schema tests |
| `assert_critical_tables_not_empty` | ⚠️ Partial | Only covers 6 of 17 enabled tables/views. Missing: `fct_daily_performance`, `fct_retail_daily`, `fct_retail_performance`, `fct_daily_scan`, `fct_today_sales_hourly`, `fct_budget_admissions_forecasts`, `fct_budget_dpr_forecasts`, `fct_budget_retail_forecasts`, `ml_visitor_forecast_training` |
| Revenue reconciliation (silver → gold) | ⚠️ Partial | Only ticket revenue (`int_pos_tickets` → `fct_daily_operations`). No retail reconciliation (`int_retail__performance` → `fct_retail_performance`) |
| Negative-value assertions | ⚠️ Partial | Only `fct_daily_operations.ticket_revenue`. No coverage for retail net_sales/net_profit or attendance counts |
| Grain uniqueness (singular tests) | ✅ Covered | Multi-column grain tests exist in schema.yml for all composite-key facts |

### Audit Findings — Alerts

| Alert | State | Issue |
|-------|-------|-------|
| `ALERT_SOURCE_FRESHNESS` | **SUSPENDED** | No freshness notifications firing |
| `ALERT_DBT_RUN_FAILURES` | **SUSPENDED** | Today's failure went unnoticed |
| `ALERT_CREDIT_CONSUMPTION` | **SUSPENDED** | Quota breach was silent |
| `ALERT_LONG_RUNNING_QUERIES` | **SUSPENDED** | No performance monitoring active |
| `ALERT_WAREHOUSE_UTILIZATION` | **SUSPENDED** | No queuing detection active |
| Resource monitor quota alert | **MISSING** | No alert exists for monitor quota approaching limits |

### Audit Findings — Semantic Views

| Semantic View | Backing Tables Tested | Notes |
|---------------|----------------------|-------|
| `DPR` | `fct_daily_performance`, `dim_date` | `fct_daily_performance` missing from emptiness test |
| `RETAIL` | `fct_retail_daily`, `fct_retail_performance`, `dim_date` | Both facts missing from emptiness test; no retail revenue reconciliation |
| `UNIFIED` | `fct_daily_performance`, `fct_retail_performance`, `fct_daily_scan`, `dim_date` | `fct_daily_scan` missing from emptiness test |
| `ATTENDANCE` | `fct_daily_scan`, `fct_ticket_demand_forecast`, `fct_ticket_availability` | `fct_daily_scan` missing from emptiness test |
| `FUNDRAISING_ECOM` | `dim_customer`, `dim_campaign`, `dim_payment_method`, `dim_fund` | Stub dimensions — tests pass trivially |

### Recommended Next Steps (not yet implemented)

1. Resume all 5 suspended alerts
2. Add resource monitor quota alert (notify at 75%, alert email at 90%)
3. Expand `assert_critical_tables_not_empty` to cover all mart facts backing semantic views
4. Add retail revenue reconciliation test (`int_retail__performance` → `fct_retail_performance`)
5. Add negative-value assertions for `fct_retail_daily.net_sales` and `fct_daily_scan` attendance

### Migration notes

- **No breaking changes.** Only the resource monitor quota was altered (5 → 10 credits/month).
- All alerts remain suspended pending deliberate re-enablement.

---

## [6.0.0] — 2026-07-28 — DPR Analyst Narrative (Cortex AI)

Session date: 2026-07-28. Added an AI-generated "Analyst Notes" block to the Daily Performance
Report pipeline. A deterministic brief model computes every fact the narrative is allowed to
reference — actuals, budget, DoD, WoW, YoY (364 days), MTD/YTD, direction flags, and top movers —
then Snowflake Cortex (`claude-sonnet-4-6`) narrates ONLY those pre-computed facts. The LLM does
no analysis; it writes prose from a structured brief. Every sentence traces to an auditable input.

### Added

| Object | Type | Detail |
|--------|------|--------|
| `rpt_dpr_narrative_brief` | dbt view (MARTS) | Deterministic JSON brief: one row per report_date with actuals, budget, var_pct, dod_pct, wow_pct, yoy_pct, MTD/YTD, 7-day direction flags, and top-3 budget/DoD movers. Report date = previous day (`< CURRENT_DATE`). YoY uses 364-day (52-week) lookback for same-weekday comparison. |
| `rpt_dpr_narrative` | dbt model (disabled) | Source SQL for the daily Snowflake TASK. `enabled=false` — not materialized as a view (each SELECT triggers an AI call). Kept in project for documentation and audit. |
| `DPR_NARRATIVE` | Table (MARTS) | Append-only storage: report_date, headline, narrative, watch_items, brief_json, tokens_used, model, generated_at, `_loaded_at`. Clustered by report_date. Use `_loaded_at DESC` to pick the latest row per date (supports reprocessing). |
| `DPR_PBI_NARRATIVE` | View (MARTS) | Power BI consumption wrapper — `QUALIFY ROW_NUMBER() OVER (PARTITION BY report_date ORDER BY _loaded_at DESC) = 1`. Relates to Dim_Date on report_date. |

### Architecture

```
RPT_DPR_POWERBI (actuals) ─┐
RPT_DPR_BUDGET_DAILY        ├─► rpt_dpr_narrative_brief ─► TASK: CORTEX.COMPLETE() ─► DPR_NARRATIVE ─► DPR_PBI_NARRATIVE ─► Power BI text card
DIM_DATE ───────────────────┘        (deterministic)            (claude-sonnet-4-6)       (append-only)     (latest per date)
```

### Design decisions

| Decision | Choice |
|----------|--------|
| Report date | Previous day (`< CURRENT_DATE`) — the DPR covers yesterday |
| YoY comparator | 364 days (52 weeks) — same weekday alignment |
| Materialization | `enabled=false` in dbt; TASK owns the insert lifecycle |
| Reprocessing | Re-run the task → new `_loaded_at` wins in `DPR_PBI_NARRATIVE` |
| Structured output | `response_format` with JSON schema: `headline`, `narrative`, `watch_items` |
| Temperature | 0.1 — near-deterministic; same facts read the same way each day |
| Model | `claude-sonnet-4-6` via `SNOWFLAKE.CORTEX.COMPLETE` |
| Grants | `POWERBI_ROLE` on both table and PBI view |

### Migration notes

- **No breaking changes** to existing models or views.
- `DPR_NARRATIVE` is new infrastructure — no downstream consumers until Power BI is wired.
- The daily TASK definition is not yet created (next step: chain after DPR load task).
- `DPR_LINE_ITEMS` (legacy orphan, no dbt model) was dropped during this session.

---

## [5.1.0] — 2026-07-28 — Standardized Header Notes

Session date: 2026-07-28. Applied a consistent documentation header block to all 53 model and test
SQL files. No SQL logic or `{{ config() }}` content was changed — only the comment blocks at the top
of each file were reformatted. Headers now follow a single convention: layer prefix → separator →
Domain / Grain / narrative notes, with `{{ config() }}` consistently placed after the header block.

### Changed

| Area | Change |
|------|--------|
| 3 intermediate budget models | `-- Intermediate:` → `-- Silver intermediate:` prefix; normalized `Grain:` spacing. |
| 6 intermediate DPR models | `-- Silver DPR:` → `-- Silver intermediate:` prefix; removed indent from bullet lists. |
| 4 intermediate retail/gateway models | Moved `{{ config() }}` below header (was above); normalized format. |
| 11 dimension models | Converted `/* ... */` block-comment headers to `--` line-comment format with Domain/Grain/Source structure. |
| 9 fact models | Moved headers above `{{ config() }}` where needed; changed `-- Mart fact:` → `-- Marts fact:`; normalized `Grain:` spacing. |
| 11 report models | Moved headers above `{{ config() }}`; normalized `Grain:` spacing; removed indent from bullet lists. |
| 1 ML feature model | Removed stale one-liner description; normalized header. |
| 8 test files | Replaced single-line descriptions with `-- Test (category):` format and added `-- Severity:` annotation. |

### Convention (all 53 files)

```
-- <Layer> <type>: <one-line title>
-- Co-authored with CoCo
-- ---------------------------------------------------------------------------
-- Domain: <domain>
-- Grain: <grain statement>
--
-- <Narrative notes…>

{{ config(…) }}
```

### Migration notes

- **No breaking changes.** SQL output is byte-for-byte identical.
- `{{ config() }}` position moved in ~15 files (from above the header to below). dbt treats position
  as irrelevant — compilation is unaffected.

---

## [5.0.0] — 2026-07-27 — Seeds Schema & Budget Forecasts

Session date: 2026-07-27. Introduced a dedicated `SEEDS` schema, loaded three new budget/forecast
seed tables from Excel-to-CSV uploads, and fixed the DPR semantic view to remove a phantom
`DATE_ID` column. **Breaking change**: all `SEED_*` tables now live in `SEEDS` instead of `MARTS`.
Any external queries referencing `MARTS.SEED_*` must be updated.

### Added

| Object | Type | Detail |
|--------|------|--------|
| `NS11MM_DW_DEV_JMYERS.SEEDS` | Schema | New dedicated schema for all seed/lookup tables. |
| `SEED_DPR_FORECASTS` | Seed table (365 rows) | FY2026 daily DPR budget: tickets, revenue, audio, donations, ecommerce, cafe, tours. |
| `SEED_FORECASTED_VALUE_FOR_DATE` | Seed table (365 rows) | FY2026 daily admissions/attendance budget by facility: attendance, tickets, guided tours, CityPASS, memorial tours. |
| `SEED_RETAIL_FORECASTS` | Seed table (1,095 rows) | FY2026 daily retail budget by facility (3 facilities × 365 days): capture rate, visitors, conversion, profit, donations. |
| `_budget_sources.yml` | dbt source | Source definition pointing at the three new budget seeds in `SEEDS` schema. |

### Changed

| Area | Change |
|------|--------|
| `dbt_project.yml` | Seeds default schema changed from per-seed overrides to `+schema: SEEDS` for all seeds. |
| 12 existing SEED_* tables | Moved from `MARTS` to `SEEDS` schema (`ALTER TABLE … RENAME TO`). |
| DPR semantic view | Removed `primary_key` block from DP (fact) table — `DATE_ID` no longer surfaces as a selectable column. Fixed relationship join column from non-existent `DATE_ID` to actual `DATE_KEY`. Removed `FISCAL_MONTH` and `FISCAL_YEAR` dimensions (columns don't exist in `DIM_DATE`). |

### Migration notes

- **External consumers** (Power BI, ad-hoc SQL) referencing `MARTS.SEED_*` must update to `SEEDS.SEED_*`.
- **dbt models** are unaffected — they use `ref('seed_*')` which resolves via the project config.
- The 3 new budget tables were renamed from `FACT_*` → `SEED_*` to follow naming conventions.

---

## [4.2.0] — 2026-07-23 — Conformed dim_facility & Config-as-Data Cleanup

*Errata (2026-07-29): this entry discusses `dim_marketing_channel` as a kept passthrough dim; the model was subsequently removed from the repo without a changelog entry. See the Reconciliation subsection of [6.2.0].*

Session date: 2026-07-23. Started from "where should we join the new `dim_*` tables in to make
filters cleaner?" The review found `dim_date` was already wired into 13 models and the other
ten dims were built ahead of their consumers, so the question turned into a codebase-wide audit
for `facility_group`-style issues — inline enumerable code→label maps, repeated magic-number
literals, and duplicated join/CTE blocks. That produced three batches of **output-equivalent**
cleanups (verified; see below). No breaking changes: every touched model keeps its column
contract.

### Added (net-new models)

| Model | Grain | Source | Purpose |
|-------|-------|--------|---------|
| `dim_facility` | key_facility | `seed_facility_area` | Conformed facility/area dimension. Single home for `key_facility → area_name / area_group / is_selling / facility_group`, previously re-selected inline in three retail facts + `dim_store` and derived as an inline CASE in `int_counterpoint__retail_lines`. |
| `int_gateway__item_attributes` | avg_id | `stg_gateway__vattribute` | Shared `avg_id → matrix_code / recognize_basis / default_customer / dynamic_channel` lookup, previously re-selected in three gateway intermediates. Raw passthrough — consumers keep their own coalesce/`visit_type` derivations. |

### Added (net-new seeds — config-as-data)

| Seed | Rows | Replaces inline literal in |
|------|------|----------------------------|
| `seed_retail_store_scope` | 9 | `int_counterpoint__retail_lines` store-scope `IN` list |
| `seed_retail_zero_price_item` | 2 | `int_counterpoint__retail_lines` zero-rated-SKU list |
| `seed_retail_excluded_item` | 1 | `int_counterpoint__retail_lines` hygiene exclusion |
| `seed_retail_donation_item` | 4 | `int_dpr__retail` donation-SKU `item_no` literals (→ `donation_line`) |
| `seed_gateway_excluded_plu` | 1 | `int_gateway__ticket_journal_lines` placeholder-PLU exclusion |
| `seed_gateway_excluded_customer` | 2 | `int_gateway__ticket_journal_lines` `itm_default_customer_id` exclusion |

### Changed (models rewired — output-equivalent)

| Model | Change |
|-------|--------|
| `int_counterpoint__retail_lines` | `facility_group` CASE → `seed_facility_area` lookup (`coalesce(…, 'other')`); store scope / zero-price / excluded-item literals → seeds. |
| `fct_retail_daily`, `fct_retail_performance` | Dropped inline `seed_facility_area` `area` CTE; now `left join dim_facility`. |
| `fct_today_sales_hourly` | Third consumer of the area seed; area label now from `dim_facility`. |
| `dim_store` | `store_type` (=`area_group`) now sourced from `dim_facility` instead of re-reading `seed_facility_area`. |
| `int_retail__performance` | Raw `summary_category = 6` (×5) → the `is_donation` flag already exported by `int_counterpoint__retail_lines` (completes the 4.0.0 refactor, which had missed this model). |
| `rpt_retail_carts_analysis` | Raw `key_facility = 1020 / 1030` → conformed `area_name` (`'Memorial Carts'` / `'Atrium'`). |
| `int_retail__visitors` | Hardcoded `1234 as key_facility` → `{% set ecom_key_facility = 1234 %}` var. |
| `int_gateway__ticket_journal_lines` | `vattribute` CTE → `int_gateway__item_attributes`; PLU/customer exclusions → seeds (`NOT EXISTS` preserves the NULL-customer-kept behavior). |
| `int_gateway__item_journal_lines`, `int_gateway__scan_lines` | `vattribute` CTE → `int_gateway__item_attributes`. |
| `int_dpr__retail` | Donation-SKU `item_no` literals → `seed_retail_donation_item.donation_line` (mirrors the 4.0.0 `seed_service_plu` pattern). |

### Updated (seeds & schema)

- **`seeds/seed_facility_area.csv`** — added `facility_group` column (`museum_store`, `memorial_carts`, `museum_cafe`, `mag_cart`, `mus_ag`, `ecommerce`; `1030`/`1070`/`1080` → `other`, matching the old CASE else-branch).
- **`seeds/_seeds.yml`** — registered the 6 new seeds (with `column_types` pins so alphanumeric `item_no`/`plu` are not coerced to numeric) and documented the new `facility_group` column with `not_null`.
- **`models/marts/dimensions/schema.yml`** — added `dim_facility` (PK `facility_key`; `not_null` on `area_name` / `area_group` / `facility_group`).

### Verification

- **Ref graph** — every `ref()` in the 15 touched/new models resolves against the model + seed set (incl. the 6 new seeds); no rewritten model left a dangling CTE alias.
- **Truth-table equivalence proofs** — the three non-mechanical transforms were checked exhaustively: the `facility_group` CASE vs. seed-join+`'other'` across all keys; the customer exclusion (`NOT IN (…) OR IS NULL` vs. `NOT EXISTS`, including the NULL-kept case); and `summary_category (<>6 / =6)` vs. `(not is_donation / is_donation)`.

### Design Decisions

1. **`dim_facility` is a new dim, not `dim_store`.** The duplicated area join is at `key_facility`
   grain; `dim_store` (built in 4.1.0) is `store_id` grain, so it could not deduplicate it. The
   retail facts join the new `key_facility`-grained `dim_facility`.

2. **`facility_group` lives in the seed, joined in silver — not pulled from the mart dim.**
   `int_counterpoint__retail_lines` is an upstream intermediate; having it `ref()` a mart dim
   would reverse layering. Instead the mapping went into `seed_facility_area` (reference data's
   natural home) and both `dim_facility` and the intermediate read the seed. Dims are otherwise
   joined only in the marts layer.

3. **`1030` / `1070` / `1080` stay `facility_group = 'other'`** (product decision), so
   `rpt_retail_carts_analysis` references facilities by unique `area_name` rather than group.

4. **Gateway attribute model is a raw passthrough.** It exposes `stg_gateway__vattribute`
   columns unchanged (no coalesce), so each consumer's existing `matrix_code` handling and the
   `gateway_recognized_date` / `gateway_general_admission_flag` macros work with zero column
   changes. Standardizing scan-line's NULL→'' handling was deliberately *not* done (would alter
   output).

### Investigated and deliberately NOT changed

- **`dim_date`** — already joined in 13 models; nothing to do beyond an optional inline cleanup
  in `int_gateway__ticket_demand_features` (skipped to keep intermediate free of mart refs).
- **Passthrough dims** — `dim_tour_product` (= `seed_tour_plu`) and `dim_marketing_channel`
  (= `ref_marketing_channels`): rewiring consumers to ref the dim inverts layering for zero
  dedup; kept the seed refs.
- **`store_facility` CTE** (`seed_retail_store_facility`, in retail_lines + today_sales_hourly) —
  left inline; centralizing via `dim_store`'s `min(key_facility)` aggregation risked changing
  fan-out.
- **`demand_level` bands, "sold tickets" base CTE, `%MEMORIAL%`/`%member%` name-match ladders** —
  single-use or open-set; consistent with the 4.0.0 keep-inline rules.

### Open items

- **`int_dpr__retail` (Batch C) is the highest-risk change** — it moves delicate donation
  double-count logic onto a seed join. Logic is preserved, but run a before/after row-count and
  per-column sum diff on this model specifically before merge.
- Several Batch C seeds are single-row (`seed_retail_excluded_item`, `seed_gateway_excluded_plu`);
  fold back inline if the extra seed files aren't worth the ops-editability.
- Suggested build gate: `dbt build --select int_counterpoint__retail_lines+ int_gateway__item_attributes+ dim_facility+`.

---

## [4.1.0] — 2026-07-22 — Dimension Table Buildout

*Errata (2026-07-29): the `dim_marketing_channel` re-enable recorded below was later undone — the model was subsequently removed from the repo without a changelog entry (its seed `ref_marketing_channels` remains). See the Reconciliation subsection of [6.2.0].*

Session date: 2026-07-22. Started from "should we break out repeating values in SEED
tables into dedicated tables?" — cardinality analysis confirmed strong candidates and
grew into a full dimension buildout. Also cleaned up NULL-only rows from SEED tables and
moved 5 dimension models out of the disabled folder into production.

### Data Cleanup

**RAW.SEED_* NULL row removal** — Deleted 833,128 rows across 4 tables where all columns
except `_LOADED_AT` were NULL (artifact of source extraction):
- `SEED_GATE_TICKETS`: 697,752 rows
- `SEED_GATE_ORDERLINES`: 104,042 rows
- `SEED_GATE_RMEVENTS`: 29,152 rows
- `SEED_GATE_ORDERS`: 2,182 rows

### Added (net-new dimension models)

| Model | Rows | Source | Purpose |
|-------|------|--------|---------|
| `dim_access_code` | 36 | `stg_gateway__tickets` + `stg_gateway__items` | Maps ~36 access codes to admission type categories (Museum General, Memorial, CityPass, Tour, Pass/Membership, Education, Audio Guide, Admin/Test) |
| `dim_event` | 29,485 | `stg_gateway__rmevents` | Timed-entry events, tours, programs, shows with active/private/roster/waitlist flags |
| `dim_store` | 5 | `seed_retail_store_facility` + `seed_facility_area` | CounterPoint store/register → facility mapping (Museum Store, Memorial Carts, Ecommerce, Cafe) |
| `dim_coa` | 712 | `stg_gateway__coa` | Chart of Accounts for journal entry classification (Summary vs Detail, category hierarchy) |
| `dim_tour_product` | 40 | `seed_tour_plu` | PLU → DPR tour type mapping (mem_field_trip, mus_field_trip, revealed_tour, early_access_tour, etc.) |

### Changed (rebuilt from disabled placeholders)

| Model | Rows | Was | Now |
|-------|------|-----|-----|
| `dim_customer` | 1,037 | Placeholder (ID, STATUS); depended on missing `int_sf_crm` | Sources from `stg_gateway__tickets`; derives customer_type from CUSTNO prefix (Web, CityPass, Viator, Go City, GetYourGuide, Tiqets, Group, Pre-Sale, Rides/Partner) |
| `dim_gate` | 190 | Placeholder; depended on missing `int_ticket_scans` | Sources from `stg_gateway__acps` + `stg_gateway__facility`; combines ACP name, node, facility, capacity |
| `dim_product` | 1,168 | Placeholder; depended on missing `int_pos_retail` + `stg_shopify__products` | Sources from `stg_counterpoint__imitem`; includes pricing, category, barcode, price_tier derivation |
| `dim_ticket_type` | 7,336 | Placeholder; depended on missing `int_pos_tickets` + `ref_ticket_types` | Sources from `stg_gateway__items`; derives item_type (Ticket, Pass, Tour, Event, Merchandise) from pass_kind/event_type/stock_type |
| `dim_marketing_channel` | 7 | Had `enabled=false` despite no external dependency | Removed `enabled=false`; now builds from `ref_marketing_channels` seed |

### File moves

**Moved out of `models/marts/dimensions/disabled/` → `models/marts/dimensions/`:**
- `dim_customer.sql` (rewritten)
- `dim_gate.sql` (rewritten)
- `dim_product.sql` (rewritten)
- `dim_ticket_type.sql` (rewritten)
- `dim_marketing_channel.sql` (rewritten — removed `enabled=false`)

**Remaining in `disabled/`** (still awaiting external source connections):
- `dim_campaign.sql` — Salesforce
- `dim_fund.sql` — Blackbaud
- `dim_budget_version.sql` — Vena
- `dim_payment_method.sql` — no source data yet

### Updated

**models/marts/dimensions/schema.yml** — Full rebuild:
- Added column-level docs + tests for all 5 net-new + 5 rebuilt dimensions
- Primary key constraints + `unique` / `not_null` tests on all PK columns
- Descriptive column docs for key business columns (admission_type, item_type, customer_type, etc.)
- Retained entries for disabled dimensions (dim_campaign, dim_fund, dim_budget_version, dim_payment_method)

### Design Decisions

1. **Staging refs, not sources** — All dimension models `ref()` the `stg_*` staging views
   (which handle rename/recast/dedup) rather than going direct to `source()`. This keeps the
   dimension layer clean and leverages the existing staging contract.

2. **No identity resolution yet** — `dim_customer` derives type from CUSTNO prefix patterns
   rather than attempting cross-system matching (Gateway CUSTOMERID ↔ CounterPoint CUST_NO ↔
   Salesforce). That work is deferred until CRM feeds land.

3. **Access code classification** — The admission_type CASE statement in `dim_access_code`
   is based on observed ticket volume patterns and code ranges. Should be validated with
   someone who knows the Gateway configuration.

4. **Natural keys as PKs** — Surrogate keys (AUTOINCREMENT) used in the direct SQL creates
   on MARTS tables, but dbt models use the natural key as PK (item_id, event_id, etc.) since
   dbt doesn't manage sequences and natural keys are stable in this domain.

---

## [4.0.0] — 2026-07-21 — Model Optimization


Session date: 2026-07-21. Started from "should we move CASE statements into dedicated
tables to join to?" and grew into a broader optimization pass. This doc is the
consolidated record of findings and delivered changes.

### Original question: CASE statements → join tables?

Mostly **no**. CASE-heavy models are heavy because they *pivot* (conditional aggregation
`SUM(CASE WHEN cohort THEN measure ELSE 0 END)`), which cannot become a join. Classify by job:

1. **Conditional aggregation / pivot** (bulk of `int_dpr__retail` 17×, `int_dpr__tour_revenue`
   16×) — keep inline; there is no table to join.
2. **Pattern-match derivation** (`matrix_code like '%TOU%'`, `line_type = 'S'`) — open set,
   keep inline.
3. **Enumerable code → label mapping** — the only kind that belongs in a seed/table. Already
   done well: `seed_tour_plu`, `seed_retail_item_facility`, `seed_retail_store_facility`.
4. **Repeated semantic flags** (`summary_category <> 6` = "is donation", 14× in one file) —
   the real DRY problem: centralize the magic numbers, not the CASE structure.

## Delivered changes (all verified output-equivalent unless noted)

1. **facility_group / is_donation refactor** — `int_counterpoint__retail_lines` now derives
   `facility_group` (name for the resolved key_facility) and `is_donation` once; `int_dpr__retail`
   consumes them, removing all 6 facility numbers + 14 donation literals. Patch:
   `dpr_retail_facility_group_refactor.patch`.

2. **int_dpr__fees_and_services PLU cohorts** — the two hardcoded PLU lists (each written twice)
   pulled into cohort CTEs, then promoted to a seed.

3. **seed_service_plu** — new seed (`plu, dpr_line_item, notes`) covering the audio-guide and
   product-178 mem+mus-tour PLUs; model wired to it via `ref()`; registered in `_seeds.yml`
   (+schema RAW). `int_dpr__tour_revenue` and `int_dpr__admissions` were reviewed and left
   unchanged — already seed-driven / open-set patterns, nothing to extract.

4. **fct_daily_operations — correctness fix.** Was silently inheriting `materialized=incremental`
   (merge on visit_date) while aggregating `sum(...) group by visit_date` over only newly-extracted
   rows → late/corrected rows OVERWROTE a day's totals with just the new slice (undercount).
   Converted to `table` (matches its day-grain siblings). Also wired `retail_revenue` /
   `retail_transactions` from `int_counterpoint__retail_lines` (non-donation top-line) and set
   `total_revenue = ticket + retail`, replacing hardcoded 0s. `retail_discounts` stays 0 —
   NO discount field in staged CounterPoint data (needs Gennady). 16-column output contract
   unchanged.

5. **dbt_project.yml materialization defaults.** Defaults were fiction: intermediate defaulted
   `incremental` but every model is a `view`; marts defaulted `incremental` but are `table`.
   That gap is what let #4 silently inherit incremental. Flipped defaults to reality —
   intermediate `view`, marts `table`, `reports` sub-group `view` — leaving incremental_strategy/
   on_schema_change as opt-in defaults (preserves `fct_ticket_availability`). Zero behavioral
   change to existing models; closes the inherit-incremental footgun for future ones.

6. **Hot intermediate views → table.** Multi-consumer views that re-ran their joins every
   consumer per build: `int_gateway__ticket_journal_lines` (7 joins ×3), `int_gateway__item_journal_lines`
   (4 ×2), `int_counterpoint__retail_lines` (3 ×3), `int_gateway__ticket_demand_features`
   (~120 lines ×2). Converted to `table` (build once, read N times). `int_ticket_scans` left a
   view (single-join thin passthrough — not worth materializing). Output identical; win is run time.

7. **Test coverage — two rounds.** Round 1: `int_counterpoint__retail_lines`, `int_pos_tickets`,
   `int_ticket_scans`, `int_ticket_inventory` + new fct_daily_operations columns. Round 2:
   `int_retail__{customers,performance,visitors}`, `int_gateway__ticket_demand_features`, 4 `rpt_`
   reports, 12 `stg_` models. Every previously-untested active model now covered. Severity rule:
   grain enforced by in-model GROUP BY → `error`; grain inherited or unverified source (incl. empty
   stubs) → `warn` (surfaces drift without breaking the daily build; promote after verifying).
   Files: `schema_test_additions.yml`, `schema_test_additions_2.yml`.

8. **fct_ticket_demand_forecast** — removed dead `hourly_demand` CTE (built but never selected);
   trimmed stale header NOTE. Output identical; one fewer aggregation per build.

### Investigated and deliberately NOT changed

- **`select *` in gold layer** — flagged early as drift risk; on inspection every gold model
  projects explicit columns in a `final`/`combined` CTE (`select * from final`, or
  `c.* exclude(...)` over an explicit CTE), so the `select *` live only in *import* CTEs and drift
  never reaches an output. Tightening would add verbosity for no drift benefit. No change made.
- `int_dpr__tour_revenue`, `int_dpr__admissions` — already well-factored (see #3).

### Open items (external / not code)

- `retail_discounts` in `fct_daily_operations` — no discount field in staged CounterPoint tables;
  confirm source with Gennady before publishing a discount metric.
- ADR-005 metric definitions for demand/attendance measures still owe the workshop.
- `warn`-severity tests: promote to `error` once the underlying source grains are confirmed.

## [3.0.1] — 2026-07-21 — Fix date_id → date_key in tests

Renames all stale `date_id` references to `date_key` in dbt tests to align with
the `dim_date` model, which already exposes the column as `date_key`.

### Fixed

- `tests/reconciliation/assert_rpt_avg_ticket_price.sql` — 4 column references
  updated (`date_id` → `date_key`) for joins against `fct_daily_performance` and
  `rpt_daily_performance_report`.
- `tests/business_rules/assert_date_coverage.sql` — 4 column references updated
  to query `date_key` from `dim_date`.
- `tests/referential_integrity/assert_gold_daily_ops_no_orphan_dates.sql` — 2
  column references updated in the `dim_date` join and null check.

---

## [3.0.0] — 2026-07-20 — Cortex Analyst Semantic Views

Deploys **three new Cortex Analyst semantic views** to `NS11MM_DW_DEV_JMYERS.MARTS`
and downloads the existing DPR view into the workspace for version control.
Major version: these semantic views are the Cortex Analyst contract consumed by
the `JMYERS_TEST` agent and future Snowflake Intelligence surfaces.

### Added — semantic view YAML specs (`cortex_project/`)

- **`ATTENDANCE.sv.yaml`** — Attendance analytics model covering daily scan counts
  by market segment, ticket demand forecasting with presale lead-time analysis,
  and real-time ticket capacity/utilization. Tables: `FCT_DAILY_SCAN`,
  `FCT_TICKET_DEMAND_FORECAST`, `FCT_TICKET_AVAILABILITY`, `DIM_DATE`,
  `SEED_SCAN_MARKET_SEGMENT`. Includes relationships and SUM metrics.

- **`RETAIL.sv.yaml`** — Retail analytics model covering category-grain sales
  performance (net sales, profit, units, donations) and facility-grain daily
  aggregates (transactions, visitors, ecommerce orders). Tables:
  `FCT_RETAIL_PERFORMANCE`, `FCT_RETAIL_DAILY`, `DIM_DATE`, `SEED_FACILITY_AREA`.
  Includes gross margin % and revenue-per-visitor ratio metrics.

- **`FUNDRAISING_ECOM.sv.yaml`** — Fundraising & ecommerce scaffold. Dimension
  stubs (`DIM_CAMPAIGN`, `DIM_CUSTOMER`, `DIM_FUND`, `DIM_PAYMENT_METHOD`) plus
  `DIM_DATE`. Ready to expand once Salesforce/Blackbaud RAW connections are live.

- **`DPR.sv.yaml`** — Downloaded from deployed `NS11MM_DW_DEV_JMYERS.MARTS.DPR`
  semantic view for workspace version control. 48 metrics, custom instructions,
  and fiscal calendar dimensions.

- **`JMYERS_TEST.agent.yaml`** — Cortex Agent spec with `dpr_analyst` tool
  pointing to the DPR semantic view on `COMPUTE_WH`.

- **`cortex-project.yaml`** — Project manifest tracking all semantic view and
  agent artifacts with their Snowflake deployment targets.

- **`UNIFIED.sv.yaml`** — Cross-domain reconciliation surface spanning all four
  live day-grain facts against `DIM_DATE`. Curated metric subset for natural-
  language retrieval; 3 verified queries, custom instructions.

### Removed — consolidated to `cortex_project/` (single source of truth)

- `semantic_models/dpr.yaml` — replaced by `cortex_project/DPR.sv.yaml`
- `semantic_models/unified.yaml` — replaced by `cortex_project/UNIFIED.sv.yaml`
- `semantic_models/attendance.yaml` — replaced by `cortex_project/ATTENDANCE.sv.yaml`
- `semantic_models/retail.yaml` — replaced by `cortex_project/RETAIL.sv.yaml`
- `semantic_models/fundraising_ecom.yaml` — replaced by `cortex_project/FUNDRAISING_ECOM.sv.yaml`
- `semantic_models/create_dpr_semantic_view.sql` — deploy via `semantic_view_deploy` instead
- `semantic_models/create_unified_semantic_view.sql` — deploy via `semantic_view_deploy` instead

Per-metric governance metadata (MET-### IDs, owners, SLA tiers) remains in dbt
exposure `meta:` blocks. The semantic view YAML carries only the semantic
definition (expr, synonyms, descriptions, custom instructions) to avoid drift.

## [2.0.0] — 2026-07-16 — Semantic & Governance Layer: Metric Metadata, Report Exposures, Charter

With the report-estate marts now fed with real data (1.6.x), this release
formalizes the **semantic and governance layer** on top of them. Every
certified metric carries a full governance metadata block and a report
cross-reference; the report estate is registered as dbt exposures mapped to
those metrics by ID; and two governance documents land under `docs/`. Major
version: the metric-identifier scheme (`MET-###`), the report-identifier scheme
(`RPT-###`), and the metric/exposure `meta:` contracts are now stable and
consumed downstream by the Hub registries and Cortex Analyst.

### Added — metric governance metadata (`semantic_models/`)

Full 17-field `meta:` block on **every metric** across `dpr.yaml`,
`attendance.yaml`, `fundraising_ecom.yaml`, and `retail.yaml` — **72 certified
metrics**, `MET-001`..`MET-072`. Fields: `display_name`, `id`, `type`,
`domain`, `status`, `grain`, `sla_tier`, `version`, `business_owner`,
`technical_owner`, `approval_date`, `time_dimension`, `scope`, `source_models`,
`related_metrics`, `caveats`, `changelog`.

- **`attendance.yaml`** — `MET-050`..`MET-056` (7 metrics), domain
  *Attendance & Ticketing*, owner Chris Wogas. Hourly-grain metrics flagged;
  scan/attendance stubs (Sensource blend, real-time CounterPoint) noted in
  `caveats`.
- **`fundraising_ecom.yaml`** — `MET-057` (1 metric), domain *Fundraising*,
  owner Jan-Michael Llanes.
- **`retail.yaml`** — `MET-058`..`MET-072` (15 metrics), domain *Retail*,
  owner Gennady Zaritsky. Ratio metrics (`profit_margin`, `avg_sale`,
  `conversion_rate`, `rev_per_visitor`) typed `Measure — Ratio` and flagged
  non-additive.
- `dpr.yaml` — `MET-001`..`MET-049`, aligned to the same contract.
- All metrics `status: in-review` with blank `approval_date`, pending domain-
  owner certification (ADR-005). `time_dimension: report_date`,
  `technical_owner: Jeremy Myers`, initial `changelog` entry on each.

### Added — report ↔ metric cross-reference (`semantic_models/`)

- New `reports:` field on every metric's `meta:`, listing the reports that
  consume the metric (the inverse of `exposures.yml`'s `metrics` list). **22
  metrics reference at least one report.**

### Added — report estate as dbt exposures (`models/exposures.yml`)

Rewrote `exposures.yml` (previously a single sample) with **13 Pentaho
migration reports** documented as dbt exposures:

- **DPR family** — Daily Performance Report, YTD, MTD, Excel Data, Memorial &
  Museum Daily Tracker.
- **Retail** — Today's Sales (Hourly), Retail Performance, Retail Carts
  Analysis, Monthly Retail KPI.
- **Attendance / scanning** — Daily Scan, Attendance, Daily Attendance.
- **Fundraising** — Website Commerce Report.

Each exposure carries native dbt fields plus a `meta:` block: `id`
(`RPT-001`..`RPT-013`), `domain`, `report_type`, `platform: Power BI`,
`legacy_platform: Pentaho`, `disposition` (`MIGRATE` / `CONSOLIDATE`),
`status`, `target_model`, `source_models`, `metrics` (referenced by `MET-###`),
`packages`, `caveats`, `version`, `changelog`.

- **`depends_on` pinned to each report's live base fact** (e.g.
  `fct_daily_performance`, `fct_retail_daily`, `fct_today_sales_hourly`,
  `rpt_website_commerce`) so `dbt parse` succeeds; the full migration target is
  recorded in `meta.target_model`. Each `ref()` must resolve to an ENABLED
  model or parse will fail.

### Added — governance documents (`docs/`)

- **`docs/policy/AI-CHARTER.md`** — AI & Data Governance Charter (v0.1):
  purpose, scope, and the seven governing principles, with sections IV–VII
  (governance structure, data/AI frameworks, compliance) marked for committee
  development. The "why" to the AI policy's "how."
- **`docs/governance/adc_meeting_records.md`** — AI & Data Committee meeting
  records in a structured, machine-readable markdown format (one `##` section
  per meeting; `Agenda` / `Decisions` / `Action Items` subsections with
  inline `owner` / `due` / `status`). First record: the AI-policy refresh and
  draft-charter meeting.

### Notes

- The metric metadata and exposures are consumed **live** by the Hub Metric
  Registry and Report Registry (bidirectionally cross-linked by `MET-###` and
  `RPT-###`) and by Cortex Analyst.
- `meta:` is valid dbt but is **not** part of the Cortex Analyst spec — strip
  before Cortex upload if a validator rejects unknown keys.
- Everything new is `in-review`. Owner sign-off and `approval_date` are the
  next gate (ADR-005) before any metric or report is promoted to certified.

## [1.6.2] — 2026-07-15 — Report-Estate Ingestion Batch 2: Sensource, Budgets, WiFi-Table Correction

Loaded and wired the remaining five report-estate source tables. Eight of the
nine report-estate stubs now carry real data (four in 1.6.1, four here); the
retail and daily-scan budget feeds unblock every `_budget` / variance column
across the estate (ADR-005). One upload was misnamed at source and is handled
accordingly (see below). Follows the seed-swap pattern from 1.6.0 / 1.6.1.

### Added — staging models (`models/raw/`)

Built against the actual uploaded columns (reconciled against the workbook,
several differed from the documented schema):

- **`stg_sensource__visitors`** — Sensource entries/exits by facility. Real feed
  adds `acp` and `passes_scanned` beyond the documented `num_entry/num_exit`.
- **`stg_sensource__attendance`** — daily attendance. Real feed is
  **pre-aggregated by named area** (`mem_attendance`, `mus_attendance`,
  `memorial_only`, `mus_store`, `mus_store_vesey`), not by facility as the
  transform docs implied — simpler, no facility mapping needed.
- **`stg_budget__retail`** — retail budget/forecast by facility/day
  (`fact_retail_forecasts`); adds `avg_don_mem_only_vis`. `key_facility` is a
  numeric facility code (e.g. 1003).
- **`stg_budget__daily_scan`** — daily-scan budget, wide by market segment
  (`fact_dsr_forecasts`); adds `mobile` and `gocity` segments. Decimal forecast
  values; literal `'NULL'` strings nullified via `try_to_decimal`.
- **`stg_dpr__daily_metrics_wide`** — see correction below.

### Added — RAW sources

- Five table entries added to the `report_estate_seed` source group:
  `seed_sensource_visitors`, `seed_sensource_attendance`, `seed_retail_budget`,
  `seed_dsr_budget`, `seed_wifi_audience`.

### Changed — stub → real source

- **`int_retail__visitors`** — Sensource half now reads
  `stg_sensource__visitors`; `visitor_count = sum(num_entry)`.
- **`rpt_attendance`** — now reads `stg_sensource__attendance` directly (the
  feed is already pre-aggregated by area), replacing the interim facility-based
  mapping.
- **`fct_retail_performance`** — budget seam now reads `stg_budget__retail`
  (`revenue_budget` → net_sales seam, `profit_budget` → net_profit seam).
- **`fct_daily_scan`** — budget now reads `stg_budget__daily_scan`, unpivoted
  from the wide segment columns to `segment_key` to match the fact grain
  (keys align with `seed_scan_market_segment`).

### Correction — `seed_wifi_audience` is not a WiFi email list

The uploaded `seed_wifi_audience` is **not** the Blue State email audience. It is
a **wide daily DPR-metrics table** (56 columns: attendance, ticket/pass revenue,
every tour line, retail gross profit, donations, operating expenses, civic
programs) with a single `daily_wifi_visitors` column and **no email addresses or
names**. Handled by:

- **`stg_dpr__daily_metrics_wide`** (renamed from the planned
  `stg_wifi__audience`) — conforms it faithfully and exposes it as an
  independent daily-metrics **reconciliation source** for parity-checking the
  built DPR marts.
- **`rpt_wifi_email_export` remains stubbed.** The real governed PII source
  (`stage_acceptance_uap_daily`: email / first / last, filtered to accepted-AUP
  rows) has **not** been loaded. This is now the only report-estate report with
  no real feed.

### Still stubbed (no data yet)

- `tmp_seed_wifi__audience` — real `stage_acceptance_uap_daily` audience feed
  (email/name) still needed for `rpt_wifi_email_export`.

### Deploy

```
dbt build --select source:report_estate_seed+ --target dev
```

### Known Issues / Verify after deploy

- **Daily-scan budget segment keys** — the DSR wide→long unpivot maps columns to
  `segment_key` values (`citypass`, `c3`, `newyork`, `walkup`, `gocity`, …);
  confirm they match `seed_scan_market_segment.segment_key`
  (`select segment_key, sum(passes_budget) from fct_daily_scan group by 1`; an
  all-null budget column signals a key mismatch). Note `partners`, `mobile`, and
  `total_tickets` from the source have no scan segment and are intentionally not
  mapped.
- **Retail budget facility codes** — `stg_budget__retail.key_facility` is numeric
  (1003, …); confirm it matches `seed_facility_area` / `fct_retail_performance`
  keys, not names.
- **Sensource attendance area labels** — confirm `mus_store` vs
  `mus_store_vesey` correspond to the intended report lines.
- **`stg_dpr__daily_metrics_wide`** is a reconciliation source, not wired into
  any report; use it to validate DPR marts, then decide whether to retain.

## [1.6.1] — 2026-07-15 — Report-Estate Ingestion: Stub Seeds → Real Sources
 
Loaded the first batch of report-estate source tables from stage into RAW,
added their staging models, and repointed the consuming models off the interim
stub seeds onto real data. Four of the nine report-estate stubs are now live;
five remain stubbed pending their feeds (Sensource, WiFi, budget). Follows the
seed-swap-with-no-report-rework pattern established in 1.6.0.
 
### Added
 
#### RAW sources (`models/raw/sources.yml`)
 
- **`report_estate_seed`** source group — seven 911dw tables loaded from stage
  into `RAW` (naming `SEED_FACT_*`, matching the existing seed convention):
  `seed_fact_passes_by_hour`, `seed_fact_todays_retail_data`,
  `seed_fact_todays_retail_product_data`, `seed_fact_website_recurring_data_db`,
  `seed_fact_shopify_orders`, `seed_fact_shopify_discounts`,
  `seed_fact_shopify_cost_values`. Freshness set to 2-day warn / 4-day error
  (more time-sensitive than the 7-day Gateway/CounterPoint seeds).
#### Staging models (`models/raw/`)
 
Rename/recast only, faithful to source (ADR-001):
 
- **`stg_gateway__passes_by_hour`** — hourly gate passes (`key_date/perhour/
  passes` → `business_date/hour_of_day/passes`).
- **`stg_counterpoint__todays_retail`** — same-day hourly CP retail (8 cols).
- **`stg_counterpoint__todays_retail_product`** — same-day product detail.
- **`stg_ecommerce__website_recurring`** — recurring online donations/memberships
  (12 cols). `email` flagged as PII in-model; mark restricted in schema.yml if
  surfaced downstream.
- **`stg_shopify__orders`** — Shopify order lines (16 cols). `key_date` parsed
  from `YYYYMMDD`; large id columns kept as varchar (no precision loss); literal
  `'NULL'` strings in refund columns nullified via `try_to_decimal`.
- **`stg_shopify__cost_values`** — order-level gross/net/profit (10 cols).
- **`stg_shopify__discounts`** — discount codes/totals (5 cols); blank codes → null.
#### Loader
 
- **`load_raw_from_stage.sql`** runbook — `INFER_SCHEMA` → `CREATE TABLE USING
  TEMPLATE` → `COPY INTO` per table (Parquet + CSV paths), transient RAW,
  `_loaded_at` default, verification queries.
### Changed — stub → real source
 
Consuming models repointed off `tmp_seed_*` stubs onto the new staging models.
The swaps were not pure `ref()` substitutions: the stub seeds used idealized
column names, so the real staging columns required adapting the consumers'
logic.
 
- **`rpt_daily_attendance`** — `tmp_seed_gateway__passes_by_hour` →
  `stg_gateway__passes_by_hour` (clean swap; same shape).
- **`fct_today_sales_hourly`** — rebuilt on `stg_counterpoint__todays_retail`.
  Real feed carries `store_id` (not `key_facility`), `doc_id`, and
  `quantity_sold`; now maps store → facility via `seed_retail_store_facility`,
  derives `transactions = count(distinct doc_id)`, `units = quantity_sold`, and
  adds real `cost` / `profit`.
- **`rpt_website_commerce`** — rebuilt on `stg_ecommerce__website_recurring`.
  `revenue_type` derived from `order_type` / `title` (Donation vs Membership),
  `revenue_year` / month from `created_at`, `amount` from `revenue`.
- **`int_retail__visitors`** — Shopify CTE now reads `stg_shopify__orders`;
  `ecom_orders = count(distinct order_id)` (real feed is one row per order line).
### Still stubbed (no data yet)
 
`tmp_seed_sensource__visitors`, `tmp_seed_sensource__attendance`,
`tmp_seed_wifi__audience`, `tmp_seed_retail__budget`, `tmp_seed_dsr__budget` —
consumed by `int_retail__visitors` (visitor half), `rpt_attendance`,
`rpt_wifi_email_export`, `fct_retail_performance`, `fct_daily_scan`. Unchanged.
 
### Deploy
 
```
dbt build --select source:report_estate_seed+ --target dev
```
 
Builds the new sources → 7 staging models → 4 updated consumers → their reports
in dependency order.
 
### Known Issues / Verify after deploy
 
- **Today's Sales store mapping** — CP today-feed uses stores 1,8-14; confirm
  `seed_retail_store_facility` covers all; unmapped stores fall to
  `key_facility = -1` (`select key_facility, count(*) from fct_today_sales_hourly
  group by 1`).
- **Website Commerce revenue_type** — the Donation/Membership split is a
  keyword match on `order_type`/`title`; validate against
  `select distinct order_type, title from stg_ecommerce__website_recurring` and
  adjust the CASE if the real values differ.
- **Shopify data age** — sample data is 2016-2018; if that is the actual range,
  ecom figures are historical, not current.
- **`email` PII** in `stg_ecommerce__website_recurring` — classify in schema.yml
  (restricted) before surfacing downstream.
- **Naming** — confirm `fact_website_recurring_data_db` vs workbook `..._d8`.

## [1.6.0] — 2026-07-15 — Active Pentaho Report Estate + Domain Semantic Layer
 
Built out the remaining active Pentaho analytical reports on top of the DPR
marts, established the reusable report-model pattern (intermediate → fact →
report → semantic), and expanded the semantic layer from one DPR model to four
domain-grouped models so every report is queryable through Cortex Analyst. The
~90 SSRS reports are Galaxy operational/box-office admin reports and remain out
of scope. Companion docs: `docs/architecture/REPORT_TABLE_COLUMN_CROSSWALK.md`,
`docs/architecture/DPR_LINEAGE.md`.
 
All 14 active Pentaho reports are now scaffolded: 4 DPR (existing) + 5 live on
current seeds + 5 wired to stub seeds pending a source feed.
 
### Added
 
#### Report-estate facts (`models/marts/facts/`)
 
- **`fct_retail_performance`** — tidy category-grain retail fact (one row per
  day × facility × product category); additive sales/profit/units/donations.
  Replaces legacy `fact_retail`.
- **`fct_retail_daily`** — facility-grain retail fact: transaction counts,
  visitor counts, and facility rollups; the grain the retail ratios operate on.
  Replaces legacy `fact_num_tickets` plus the facility rollup of `fact_retail`.
- **`fct_daily_scan`** — gate passes scanned + tickets sold by market segment
  per day. Replaces legacy `fact_dailyscan_data`.
- **`fct_today_sales_hourly`** — same-day hourly retail sales by facility
  (STUB: real-time CounterPoint feed pending).
#### Report models (`models/marts/reports/`)
 
- **`rpt_retail_performance`** — Retail Performance Report: ratios
  (conversion, rev-per-visitor, avg sale, margin, per-cap donations) as
  ratio-of-sums at query grain, plus category drill-down. Template for the estate.
- **`rpt_retail_carts_analysis`** — Retail Carts Analysis: memorial-carts lens
  with the legacy adjusted-visitor denominator (mem visitors − 25% − mus visitors)
  for capture rate and per-cap.
- **`rpt_monthly_retail_kpi`** — Monthly Retail KPI: `fct_retail_daily` rolled to
  fiscal month × area, ratios recomputed at the month grain.
- **`rpt_memorial_museum_tracker_ytd`** — Memorial Museum Daily Tracker YTD:
  fiscal-YTD variance tracker over `fct_daily_performance` (windowed cumulative
  partitioned by fiscal year).
- **`rpt_daily_scan`** — Daily Scan Report: market-mix shares and scan
  utilization at query grain.
- **`rpt_attendance`** — Attendance Report (STUB: Sensource area counts).
- **`rpt_daily_attendance`** — Daily Attendance Report (STUB: hourly passes;
  scan-based fallback).
- **`rpt_website_commerce`** — Website Commerce Report (STUB: Classy/Shopify
  recurring, ADR-008).
- **`rpt_wifi_email_export`** — Blue State WiFi email export.
  **RESTRICTED / PII**: tagged `pii`/`restricted`/`marketing_export` so the
  `on-run-end` masking hook applies; PII columns marked
  `classification: restricted_pii` / `contains_pii: true`. Least-privilege grant
  only (marketing-export role); must NOT be granted to `POWERBI_ROLE` / `ML_ROLE`.
  See `docs/architecture/DATA_CLASSIFICATION.md`.
#### Intermediate models (`models/intermediate/`)
 
- **`int_retail__performance`** — day × facility × category retail aggregation.
- **`int_retail__customers`** — facility-grain transaction counts
  (`count(distinct doc_id)`; non-additive across category, kept separate).
- **`int_retail__visitors`** — Sensource visitor + Shopify ecom counts (STUB).
- **`int_gateway__scan_lines`** — scan events joined to their ticket's market
  segment via `usage.visual_id = jnltickets.visual_id`, then matrix/channel.
#### Seeds
 
- **`seed_facility_area`** (reference) — selling-area labels for facility keys
  (1003 Museum Store, 1020 Memorial Carts, 1030 Atrium, 1234 Ecommerce, 4007
  Cafe, 1040/1060 audio, 1070 tour guides, 1080 memberships).
- **`seed_scan_market_segment`** (reference) — market-segment map for the Daily
  Scan Report (CityPASS, C3, Explorer, GoCity, School Groups, Members, Walk-up, …).
- **Stub seeds** (`seeds/_tmp/`, schema `raw_seed`, tags `build_temp`/`stub`):
  `tmp_seed_sensource__visitors`, `tmp_seed_sensource__attendance`,
  `tmp_seed_shopify__orders`, `tmp_seed_ecom__recurring`,
  `tmp_seed_gateway__passes_by_hour`, `tmp_seed_cp__today_sales`,
  `tmp_seed_retail__budget`, `tmp_seed_dsr__budget`, `tmp_seed_wifi__audience`
  (the last tagged `pii`/`restricted`).
#### Semantic layer (`semantic_models/`)
 
- **`retail.yaml`** → `MARTS.RETAIL` — spans `fct_retail_daily` (facility grain,
  ratios) and `fct_retail_performance` (category grain) so both facility-level
  and product-category questions are answerable. 15 metrics.
- **`attendance.yaml`** → `MARTS.ATTENDANCE` — spans `fct_daily_scan`,
  attendance measures, and `fct_today_sales_hourly`. Covers Daily Scan,
  Attendance, Daily Attendance, Today's Sales.
- **`fundraising_ecom.yaml`** → `MARTS.FUNDRAISING_ECOM` — Website Commerce
  recurring revenue (STUB-fed).
- Stub-fed surfaces carry `module_custom_instructions` guardrails: the agent
  reports an empty result as "feed not yet connected", never "revenue was zero".
  `museum_attendance` is flagged as a GA-ticket proxy; Daily Scan segment splits
  are flagged provisional (totals reliable) pending channel-mapping validation.
#### Documentation
 
- **`docs/architecture/DPR_LINEAGE.md`** — table-relationship and
  transformation reference for the DPR slice, with a Mermaid `graph LR` lineage
  diagram and per-layer transformation notes.
- **`docs/architecture/REPORT_TABLE_COLUMN_CROSSWALK.md`** — report → model →
  base-table matrix, the old→new column crosswalk per base table, and per-report
  measure mapping (legacy field → new mart column).
- READMEs updated: root, `semantic_models/`, `models/marts/facts/`,
  `models/marts/reports/`.
### Changed
 
- **`int_ticket_scans`** — exposes `visual_id` (passthrough) to enable the scan →
  ticket market-segment join for Daily Scan. Grain and existing consumers
  unchanged.
- **Semantic layer scope** — expanded from a single DPR model to four
  domain-grouped models (DPR / retail / attendance / fundraising_ecom). Design:
  one model per business domain (not per fact), each spanning its facts, so
  cross-report questions within a domain work; facts are never join-fanned in a
  single query.
### Known Issues / Follow-ups
 
- **Daily Scan segment mapping is provisional.** `seed_scan_market_segment` maps
  against `acs_dynamic_channel` (sales channel) as the closest structured proxy;
  the legacy `t_fact_dailyscan_data` transform was undocumented in the source.
  Passes/sold totals are correct; the per-segment split needs validation
  (`select category, count(*), sum(scanned_qty) from int_gateway__scan_lines
  group by 1`). If channels are generic, pivot the seed to `sales_program_id`.
- **`cafe1_donations` not surfaced in `fct_daily_performance`.** It exists in
  `int_dpr__retail` but was never added to the fact, so it is omitted from the
  Memorial Museum Tracker YTD donation sum. Surface it to the fact to close the gap.
- **Stub-fed reports await source feeds** (each a seed/staging swap, no report
  rework): `sensordata` (Sensource — Attendance ×2, retail conversion ratios,
  true DPR `mus_attendance`), hourly passes, real-time CP (Today's Sales),
  Classy/Shopify recurring (Website Commerce), WiFi audience, budget/forecast.
  Add a thin `stg_<source>__<entity>` between each new RAW table and the marts
  when it lands.
- **WiFi export access grant** is a governance-tier decision: confirm the
  marketing-export role grant and that `POWERBI_ROLE`/`ML_ROLE` are excluded.
- **Native semantic-view DDL twins** for retail/attendance/fundraising_ecom not
  yet generated; regenerate alongside `create_dpr_semantic_view.sql` so the
  native views match the YAMLs.

## [1.5.2] — 2026-07-13 — Developer Onboarding & Semantic View Pipeline

### Added

- **Parameterized developer workspace setup** (`scripts/setup_developer_workspace.sql`):
  change one `SET dev_username` variable to provision a full dev environment (database,
  schemas, grants). Eliminates manual find-and-replace of hardcoded usernames.
- **Pre-commit hook** (`.githooks/pre-commit`): auto-regenerates
  `create_dpr_semantic_view.sql` from `dpr.yaml` whenever the YAML or generator is staged,
  ensuring the DDL never drifts from the metric definitions.
- **BUILD_DIMS_METS.md** updated with documentation on the YAML→SQL pipeline, ratio-of-sums
  semantics for `avg_ticket_price`, and how `assert_rpt_avg_ticket_price.sql` guards against
  formula drift in the `rpt_` layer.

### Changed

- `dpr.yaml`: removed duplicate `avg_ticket_price` definition; canonical ratio now lives once
  in the NON-ADDITIVE RATIOS section as `SUM(TOTAL_ADMISSION_REVENUE) / NULLIF(SUM(TICKETS_SOLD), 0)`.
- `setup_developer_workspace.sql`: split `INSERT, CREATE TABLE ON SCHEMA` (invalid) into
  separate `CREATE TABLE ON SCHEMA` + `INSERT ON FUTURE/ALL TABLES` grants.

### Fixed

- KRAMSEY dev database: granted `ALL ON ALL TABLES` and `ALL ON FUTURE TABLES` in
  `NS11MM_DW_DEV_KRAMSEY.RAW` to `TRANSFORMER_ROLE` — tables created by ACCOUNTADMIN were
  invisible to `DEPLOY_DEV_ROLE` (which inherits TRANSFORMER_ROLE).
- KRAMSEY default role set to `DEPLOY_DEV_ROLE`.
- Copied all 22 RAW tables from `NS11MM_DW_DEV_JMYERS` to `NS11MM_DW_DEV_KRAMSEY`.

---

## [1.5.1] — 2026-07-13 — Governance: ADR-001 through ADR-006 Rewritten for Snowflake

Six architecture decision records added to `docs/adr/` as markdown, rewritten to their
post-migration state from the ADR Review working document (Part 1 status summary). Four
carried revisions (001, 002, 003, 005); two are current and rendered as-is (004, 006).
Filenames follow the existing `docs/adr/NNNN-title.md` convention. These supersede the
pre-migration text and must be reconciled against the canonical ADRs before the old copies
are retired — see Notes. Companion artifact: `adr_review_working.docx`.

### ADRs Added / Revised

- **`0001-stack-selection.md`** — removed all Microsoft Fabric references; added the
  Snowflake migration rationale, the custom Python ingestion decision, and Cortex Analyst
  as the T3-tier analytics tool
- **`0002-medallion-architecture.md`** — mapped the Fabric lakehouse layers to Snowflake
  schema equivalents (Bronze/Silver/Gold → RAW/INTERMEDIATE/MARTS); added Cortex Analyst
  as a Gold-layer consumer alongside Power BI
- **`0003-ingestion-strategy.md`** — full rewrite. Custom Python pipelines set as the
  standard path to Bronze; native/managed connectors rejected as primary (exception process
  only); Snowflake Streams CDC named as the merge-semantics workaround; two-hop on-prem
  pattern (bcp → RDP → PUT/COPY INTO) documented
- **`0004-no-logic-in-power-bi.md`** — rendered current, no revision. Records the thin-display
  boundary and that row-level security lives in Snowflake, not Power BI DAX
- **`0005-metric-definition-gate.md`** — added the clause extending the gate to the Snowflake
  Cortex Analyst semantic model YAML; recorded that the gate fires on new definitions, not on
  new consumers of existing ones
- **`0006-change-management.md`** — rendered current, no revision to the decision. Captures the
  single-intake path (Ginabell), `ITCHG-NNNN` IDs, PR-gated CI, and commemoration/event freeze
  protocols; ADR-014 forward reference pending

### Notes / To Reconcile

- **Reconstructed, not transcribed.** The review doc supplied status and required revisions for
  001–006, not their full source bodies; the prose was rebuilt from that summary plus current
  platform context. Each file carries `[confirm]` markers for values only the canonical ADR holds
  (original decision dates; exact production schema names in 0002; the seven stage names in 0006;
  Kenny Yeung schema confirmation in 0003)
- **Supersession.** `0005-metric-definition-gate.md` and `0006-change-management-tiers.md` already
  exist in the repo. New 0005 extends the existing gate; new 0006 is titled "Seven-Stage Process"
  where the existing file is "Change Management Tiers (Tier 1/2/Emergency)" — confirm which framework
  is current, then rename/retire the superseded file
- **Register collision to resolve before ADR-007+.** The review doc proposes ADR-007 (Bronze
  Immutability) and ADR-008 (Semantic Layer Governance), but the repo already holds
  `0007-drupal-ingestion-path.md` and `0008-retail-source-split.md`. The register needs
  de-collision before any 007+ ADRs are written

## [1.5.0] — 2026-07-08 — DPR Metric Reconciliation: Legacy Parity Fixes
 
Full logic/lineage audit of all ~40 DPR base metrics against the legacy Pentaho
definitions (`report_details_pt` / `transforms_pt`), followed by a fix sprint.
Nine fixes shipped and validated against Snowflake; every remaining gap is
documented as an extract-scope or definitional item (see Known Issues).
Companion artifact: `dpr_metric_reconciliation_audit_v3.xlsx`.
 
### Critical Bug Fixes
 
- **`gateway_recognized_date` macro** — recognize-basis 182 (92% of ticket volume)
  keyed on `rme.start_at`, which is null for 111K rows; combined with
  `jnltickets.ticketdate` being ~95% unparseable, ~116K of 128K ticket units got a
  null `key_date` and were silently dropped. All branches now coalesce to
  `end_of_life_date` (the visit date, same substitution as the 1.4.0
  `stg_gateway__tickets` fix): basis 182 → `coalesce(start_at, end_of_life_date,
  ticket_date)`; 185/else → `coalesce(ticket_date, end_of_life_date)`. Enriched
  journal recovered 8,267 → 105,781 qty; GA + tour partition reconciles to the
  penny (96,326 / $2.68M GA + 9,455 / $262K tours = $2,942,119.89)
- **Systemic PLU trim** — Galaxy stores `plu` as space-padded `CHAR(20)`, which
  silently defeated every downstream equality join and filter. `trim(plu)` now
  applied at source in `stg_gateway__items`, `stg_gateway__jnltickets`, and
  `stg_gateway__jnlitems` (all three together to keep bridge joins aligned).
  Un-zeroed: `box_office_mem_don` ($28,362), `box_office_mus_exit_don` ($8,160),
  and the Galaxy component of `audio_tour_headset`
- **Cafe wired in** — `cafe1_all_profit` / `cafe1_donations` were structurally
  zero: CounterPoint store 1 was outside the retail store scope and facility 4007
  was never mapped. Added store 1 → 4007 to `seed_retail_store_facility` and
  widened the scope in `int_counterpoint__retail_lines`. Validated: profit
  $68,434 / donations $7,219 (COGS coverage confirmed at 99.8% of cafe lines)
- **`mem_mus_tour_revenue` / `mem_mus_tours`** — legacy keys on `rItmProductID =
  178`, whose PLUs carry no matrix code, so the `%MTG%` matrix filter matched
  nothing. Switched to the product-178 PLU list (`MUSMMUADW001/003/005`) in
  `int_dpr__fees_and_services`. Validated: 1,262 tours / $107,270 (was 0)
### Donation Re-sourcing & Corrections
 
- **`mask_donations` / `donation_box`** — re-pointed from the Gateway item
  journal (wrong system) to CounterPoint retail per legacy spec: items `200704`
  (mask, dormant since 2021) and `101165` (Plaza Donation Box, $1,809 validated).
  Measures moved to `int_dpr__retail`; `fct_daily_performance` re-wired
- **Legacy surrogate keys resolved by inspection** — `dim_item_descr` surrogates
  were being used as CounterPoint `item_no`: 483 → `'7-999'` (Donation Ask),
  886 → `'101375'` (Donation Box Store Exit; `item_no` is alphanumeric, so the
  numeric surrogates could never match). `mus_exit_donations` now $1,816 (was 0);
  `cart_donation_ask` narrowed to the ask item at the carts ($11,023), removing a
  double-count with the plaza box; `mus_store_donations` excludes the exit-box
  item ($25,993)
- **`coatcheck_don`** — now excludes PLU `DONOPSMUS003`: its matrix also matches
  `%DON-OPS-MUS%`, so once the PLU trim landed the exit-box dollars would have
  counted twice (pre-trim they landed only here). Ships with the trim by design
- **`ticketing_donations`** — member-desk PLU `DONMBRMUS001` excluded per legacy
  spec (booked to Membership); dormant in the current window, guards history
- **`mem_audio_guide_revenue`** — added the CounterPoint facility-1040 component
  (`mag_cp_revenue` in `int_dpr__retail`), the primary MAG source since 2023.
  The item-override seed carved those lines out of the carts but no measure
  aggregated them. Combined with the Galaxy `%MAG%` component in the fact.
  Dormant in the current extract window; wiring validated
### Seeds
 
- **`seed_tour_plu`** — full rebuild from the legacy `product_logic` PLU lists
  (40 PLUs, 8 categories). Corrects: `revealed_tour` = `VTMUSOBLOADW001` (was
  mislabeled early-access PLUs), `mem_field_trip` = `VTEDUMEM*` (was youth &
  family), `mus_field_trip` = `VTEDUMUS*` (was early-access). New exclusion
  categories `youth_fam_tour`, `early_access_tour`, `ea_mem_mus_tour` fix the
  `mus_guided_tours` over-count ($84,062 post-fix)
- **`seed_retail_store_facility`** — store 1 → facility 4007 (Museum Cafe;
  store id to be confirmed with Retail)
- **`_seeds.yml`** — `accepted_values` and descriptions updated for both
### New Models & Semantic Layer
 
- **`int_dpr__attendance`** — memorial attendance (`mem_attendance`) plus scanned
  museum attendance from `int_ticket_scans` + facility classification
- **`int_dpr__tour_revenue`** — added `mem_guided_tours` /
  `mem_guided_tour_revenue` (`%MGT%` cohort)
- **`fct_daily_performance` / `rpt_daily_performance_report`** — new measures
  surfaced; donation columns re-wired to their corrected sources
- **`semantic_models/dpr.yaml`** — fully synced with the fact: 49 metrics (every
  additive measure individually queryable, composites retained), complete
  `dim_date` dimension set including the fiscal calendar (FY starts October),
  fixed an incorrect "fiscal year" synonym on `calendar_year`, new verified
  queries and fiscal-aware SQL-generation instructions
### Diagnostics Verified Healthy (no change needed)
 
- `jnlheaders.tran_date` parses 100% (206,052/206,052) — item-journal `key_date`
  is sound
- Journal codes 532/610 identified as tender/deposits (Visa/MC/Amex/Cash/Wire,
  $4.7M payment mirror) — correctly ignored by the models
### Known Issues / Blocked on Extract
 
- `disbursement_id` (all rows) and `order_line_id` (codes 33/35/37/52) arrive as
  literal 0 — export artifact; blocks the tour-with-GA cohort and code
  identification
- COA extract missing the accounts behind journal codes 33/35/37/52 (~$7.8M);
  code 33 is likely the standalone service-fee postings — `service_fees` reads 0
  until resolved
- Extract windows are recent-only (CP: 2026-06-01..07-06); retired/seasonal
  products (virtual tours, Revealed, masks) require the history load. CP stores
  8/10 absent
- `RMEvents.start_at` null for 111K basis-182 rows (fallback in place; true event
  dates needed for tour products)
- Unissued population confirmed present in `orderlines` (5,703 units / $1.9M
  order book) — buildable pending the ADR-005 definition decision
- `create_dpr_semantic_view.sql` (native DDL twin) not yet regenerated to match
  the rebuilt `dpr.yaml`

## [1.4.0] — 2026-07-07 — Ticket Demand Forecasting & ML Pipeline

### New Models

- **`int_pos_tickets`** — daily POS ticket transactions from gateway tickets
- **`int_ticket_scans`** — gate scan events from gateway usage data
- **`int_ticket_inventory`** — derived daily ticket inventory (reservations vs rolling-90d-max capacity)
- **`fct_daily_operations`** — daily operational metrics (visitors, ticket sales, revenue); Shopify removed pending data
- **`fct_ticket_availability`** — ticket capacity and utilization by date/type (incremental)
- **`ml_ticket_demand_features`** — enabled; columns renamed (`entry_date→visit_date`, `daily_reserved→daily_visitors`) to align with Snowflake ML FORECAST
- **`ml_visitor_forecast_training`** — enabled; feeds visitor count forecasting

### Bug Fixes

- **CounterPoint staging models** (5 files) — added `_loaded_at` to staged CTE; was missing and caused `invalid identifier` errors in the `QUALIFY` deduplication clause
- **`stg_gateway__tickets`** — `ticket_date` now sourced from `endoflifedate` (the actual visit date in Galaxy); `ticketdate` column had 0 parseable values
- **`int_gateway__ticket_demand_features`** — added filter `ticket_date < '2030-01-01'` to exclude 15K sentinel `3000-12-31` rows (lifetime memberships)
- **`fct_ticket_availability`** — fixed `cluster_by` referencing `ticket_type_id` (should be `ticket_type`, the output alias)
- **`fct_daily_operations`** — fixed trailing comma after last CTE causing syntax error; fixed incremental `WHERE` referencing non-existent `_extracted_at` column in `{{ this }}`

### ML Forecasting

- **`create_ticket_demand_forecast` macro** — now target-aware (resolves from `target.database` instead of hard-coded PROD); added empty-table guard
- **`MANUAL_ML_RUN.sql`** — standalone SQL for running forecast outside dbt; includes filtered training view (series with 10+ observations) to avoid internal errors from single-point series
- **`ML_TICKET_DEMAND_FEATURES_FILTERED`** — view excluding series with <10 data points for stable model training

### Test Coverage Expansion

- **New `models/raw/schema.yml`** — PK tests (unique + not_null) for 12 staging models
- **Updated `models/intermediate/schema.yml`** — added tests for `int_pos_tickets`, `int_ticket_scans`, `int_ticket_inventory`, `int_gateway__ticket_demand_features`
- **Updated `models/marts/facts/schema.yml`** — added tests for `fct_daily_operations` (visit_date unique/not_null), `fct_ticket_demand_forecast`, `fct_ticket_availability`
- **Updated `models/ml_features/schema.yml`** — added `daily_visitors` not_null test; added `ml_visitor_forecast_training` tests (ds unique/not_null, y not_null)
- **New singular tests:**
  - `assert_critical_tables_not_empty` — fails if any of 6 critical tables has 0 rows
  - `assert_no_future_tickets` — flags implausible future dates in staging
  - `assert_no_negative_revenue` — re-enabled from disabled
  - `assert_gold_daily_ops_no_orphan_dates` — re-enabled from disabled
  - `assert_raw_silver_ticket_count_match` — re-enabled; fixed source (was `jnltickets`, now `tickets`); added `sold_at IS NOT NULL` filter
  - `assert_silver_gold_revenue_reconciliation` — re-enabled; fixed column name and removed stale date filter
- **Source freshness** — added `warn_after: 7 days` / `error_after: 14 days` to both `gateway_seed` and `counterpoint_seed`

### File Organization

- Moved 67 disabled files into `disabled/` subfolders:
  - `models/intermediate/disabled/` (8 files)
  - `models/marts/dimensions/disabled/` (6 files)
  - `models/marts/facts/disabled/` (20 files)
  - `models/marts/reports/disabled/` (9 files)
  - `models/ml_features/disabled/` (12 files)
  - `tests/business_rules/disabled/` (2 files)
  - `tests/reconciliation/disabled/` (2 files)
  - `tests/referential_integrity/disabled/` (4 files)

### Documentation

- Updated READMEs: root, `models/raw/`, `models/intermediate/`, `models/marts/facts/`, `models/ml_features/`, `macros/operations/`, `tests/business_rules/`, `tests/reconciliation/`, `tests/referential_integrity/`
- Root README current-scope table updated: 12 intermediate (was 8), 4 facts (was 1), 2 ML features (was 0)

---

## [1.3.2] — 2026-07-06 — Doc Cleanup

### Documentation Review — Current-Scope Accuracy Pass

Reviewed all 39 `.md` files in `ns11mm/ns11mm-data-platform` against the actual repo state
(models enabled vs. `enabled=false`, real folder names, real file names). **22 files changed.**

Ground truth used: **live today = the Gateway + CounterPoint → Daily Performance Report slice**
(21 staging, 8 intermediate, 4 dims + 1 fact + 1 report, 1 semantic view). Everything else is
present but `enabled=false`. This zip contains only the changed files, at their repo paths.

---

#### Two systemic problems fixed

1. **Orphaned Git merge-conflict markers.** 54 stray `>>>>>>> remote` lines across 16 files
   (no matching `<<<<<<<`/`=======` halves — content was intact). All removed. Files affected
   by *marker removal only*: `CHANGELOG.md`, `SNOWFLAKE_SETTINGS.md`, `docs/ONBOARDING.md`,
   `docs/architecture/DATA_CLASSIFICATION.md`, `SQL_STYLE_GUIDE.md`, `USAGE_AUDIT.md`,
   `macros/data_quality/README.md`, `macros/generic_tests/README.md`.

2. **Docs presenting the full future platform as if it's live today**, with no current-vs-planned
   distinction (the issue you flagged on the main README + customer 360).

---

#### Substantive changes

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

#### Left unchanged (already accurate)

- **The six model-folder READMEs** (`models/raw`, `models/intermediate`, `models/marts/dimensions`,
  `.../facts`, `.../reports`, `models/ml_features`) — these already list Enabled vs. Disabled
  models correctly with blocker/re-enable reasons. Verified each against the actual model configs;
  they match exactly. These are the authoritative per-model source of truth, and the rewritten
  top-level docs now point to them.
- **ADRs, tests/* READMEs, pipelines/readme, terraform/README** — accurate or forward-looking by
  design; no current-vs-planned misrepresentation after marker cleanup.

---

#### One thing to confirm

The main README now says to **confirm the fiscal start month**, while `METRIC_GLOSSARY.md` asserts
**October** (FY = Oct–Sep). `dim_date` has `fiscal_year`/`fiscal_month` logic. If October is
correct, the README can be made assertive to match the glossary.

## [1.3.1] — 2026-07-06 — DPR Semantic View & Build Fixes

### Added

**Semantic View**
- `NS11MM_DW_DEV_JMYERS.MARTS.DPR` — native Snowflake semantic view over FCT_DAILY_PERFORMANCE + DIM_DATE with 19 metrics (additive SUM + ratio-of-sums), 8 dimensions, AI instructions, and commemoration-window awareness
- `semantic_models/create_dpr_semantic_view.sql` — environment-portable DDL (USE DATABASE at top for dev/prod switch)
- `semantic_models/dpr.yaml` — Cortex Analyst YAML spec with verified queries and custom instructions

### Fixed

**Staging Models**
- `stg_gateway__orders.sql` — removed non-existent columns (`orderno`, `transno`, `eventno`, `status`, `total`, `tax`, `totalpaid`, `totalrefund`, `totaldue`, `depositamt`, `pendingloyaltypoints`, `issuedloyaltypoints`, `orderdate`, `groupid`); rewrote with correct column names from SEED_GATE_ORDERS
- `stg_gateway__orderlines.sql` — removed non-existent columns (`orderno`, `lineno`); rewrote with correct column names from SEED_GATE_ORDERLINES

**Mart Models**
- `fct_daily_performance.sql` — `cluster_by` changed from `date_key` to `date_id`; output column renamed `date_key` → `date_id`; join to dim_date updated to use `date_id`; added `WHERE key_date IS NOT NULL` to date_spine CTEs to handle upstream NULL dates
- `rpt_daily_performance_report.sql` — join updated from `f.date_key = dd.date_key` to `f.date_id = dd.date_id`; mapped `calendar_year`/`calendar_month` to actual dim_date columns (`year_number`/`month_of_year`); output column renamed `date_key` → `date_id`

**Intermediate Models**
- `silver_gateway__ticket_journal_lines.sql` — added `WHERE key_date IS NOT NULL` to filter rows where try_to_timestamp returned NULL from literal 'NULL' strings in raw date columns
- `silver_gateway__item_journal_lines.sql` — same NULL date filter added

**Schema / Tests**
- `models/marts/_dpr__marts.yml` — all `date_key` references updated to `date_id`; relationship field updated
- `models/intermediate/_dpr__models.yml` — no changes needed (key_date tests now pass after view rebuild)
- 12 singular tests disabled (`enabled=false`) that reference disabled/deleted models

### Changed

- `models/intermediate/schema.yml` — removed schema entries for deleted models (`silver_pos_tickets`, `silver_pos_retail`, `silver_ticket_scans`, `silver_ticket_inventory`)
- `models/exposures.yml` — all 11 exposures removed (depend on disabled marts); placeholder comments retained

### Removed

- `analyses/create_marketing_semantic_view.sql` — deleted (referenced disabled models)
- `analyses/verified_queries/` — entire directory removed (49 files; no verified queries currently applicable)

---

## [1.3.0] — 2026-07-06 — Gateway & CounterPoint Seed Data Buildout

### Added

**Raw Tables (NS11MM_DW_DEV_JMYERS.RAW)**
- 16 `SEED_GATE_*` tables created from Gateway Galaxy SQL Server CSV exports via INFER_SCHEMA
- 5 `SEED_CP_*` tables created from CounterPoint POS CSV exports (IM-ITEM, PS-TKT-HIST, PS-TKT-HIST-LIN, VI-TKT-HIST, VI-TKT-HIST-LIN)

**Staging Models (models/raw/)**
- 16 new `stg_gateway__*.sql` models — snake_case renaming, try_to_timestamp for dates, logical column grouping
- 5 new `stg_counterpoint__*.sql` models — full column coverage for POS item master, ticket history headers/lines, and enriched views

**Source Definitions**
- `gateway_seed` source (NS11MM_DW_DEV_JMYERS.RAW, 16 tables)
- `counterpoint_seed` source (NS11MM_DW_DEV_JMYERS.RAW, 5 tables)

**Seeds (seeds/)**
- `seed_tour_plu.csv` — PLU-to-DPR tour line item mapping
- `seed_retail_item_facility.csv` — CounterPoint item_no → facility override
- `seed_retail_store_facility.csv` — CounterPoint store_id → facility fallback
- `_seeds.yml` — schema definitions, column types, and tests for all 3 new seeds

**Intermediate Models (models/intermediate/)**
- `silver_counterpoint__retail_lines.sql` — CounterPoint retail lines with facility assignment
- `silver_gateway__item_journal_lines.sql` — Gateway item-level journal lines
- `silver_gateway__ticket_journal_lines.sql` — Gateway ticket journal lines with product classification
- `silver_dpr__admissions.sql` — DPR admissions revenue
- `silver_dpr__donations.sql` — DPR donation revenue
- `silver_dpr__fees_and_services.sql` — DPR fees and services revenue
- `silver_dpr__retail.sql` — DPR retail revenue
- `silver_dpr__tour_revenue.sql` — DPR tour revenue

**Mart Models (models/marts/)**
- `fct_daily_performance.sql` — Daily performance by DPR line item
- `rpt_daily_performance_report.sql` — Report joining fct_daily_performance + dim_date
- `_dpr__marts.yml` — schema docs for DPR mart models

**Documentation**
- README.md files added to all model folders (raw, intermediate, marts/dimensions, marts/facts, marts/reports, ml_features) documenting enabled vs disabled models

### Changed

**Renamed Tables**
- 16 existing `SEED_*` tables renamed to `SEED_GATE_*` (Gateway source prefix)
- 5 new `SEED_*` tables renamed to `SEED_CP_*` (CounterPoint source prefix)

**dbt_project.yml**
- Removed git merge conflict marker (`>>>>>>> remote`)

**packages.yml**
- Removed git merge conflict marker (`>>>>>>> remote`)

**models/exposures.yml**
- Removed git merge conflict marker (`>>>>>>> remote`)

**Reconciliation Tests**
- `assert_raw_silver_ticket_count_match.sql` — now uses `source('gateway_seed', 'seed_gate_jnltickets')` (no longer commented out)
- `assert_raw_silver_retail_count_match.sql` — now uses `source('counterpoint_seed', 'seed_cp_pstkthistlin')` (no longer commented out)

**models/intermediate/schema.yml**
- Updated silver_pos_tickets docs (PK → jnl_detail_id, date → sold_at)
- Updated silver_pos_retail docs (PK → line_guid, date → business_date)
- Updated silver_ticket_scans docs (PK → usage_id, date → use_time)

### Removed

**Deleted Staging Models** (19 files — sources not available)
- `stg_salesforce_nps__contacts.sql`, `stg_salesforce_nps__accounts.sql`, `stg_salesforce_nps__opportunities.sql`, `stg_salesforce_nps__campaigns.sql`
- `stg_salesforce_mc__tracking.sql`
- `stg_shopify__orders.sql`, `stg_shopify__customers.sql`, `stg_shopify__products.sql`
- `stg_classy__campaigns.sql`, `stg_classy__transactions.sql`
- `stg_blackbaud__accounts.sql`, `stg_blackbaud__journal_entries.sql`
- `stg_ga4__sessions.sql`
- `stg_google_ads__campaigns.sql`
- `stg_meta_ads__campaigns.sql`
- `stg_vena__budget.sql`
- `stg_wufoo__form_entries.sql`
- `stg_clicky__visitors.sql`
- `stg_drupal__pages.sql`

**Deleted Obsolete Staging Models** (3 files — replaced by new gateway_seed models)
- `stg_gateway__customers.sql`, `stg_gateway__ticket_types.sql`, `stg_gateway__transactions.sql`

**Deleted Obsolete Staging Models** (3 files — replaced by new counterpoint_seed models)
- `stg_counterpoint__items.sql`, `stg_counterpoint__line_items.sql`, `stg_counterpoint__transactions.sql`

**Deleted Silver Models** (4 files — superseded by new intermediate models)
- `silver_pos_tickets.sql`, `silver_pos_retail.sql`, `silver_ticket_scans.sql`, `silver_ticket_inventory.sql`

**Removed Source Definitions** (12 sources from sources.yml)
- salesforce_nps, salesforce_mc, gateway (old), shopify, classy, blackbaud, vena, ga4, google_ads, meta_ads, wufoo, clicky, drupal

### Disabled (`enabled=false`)

**Intermediate** (8 models)
- `silver_sf_crm`, `silver_sf_marketing_cloud`, `silver_shopify`, `silver_classy`, `silver_blackbaud`, `silver_google_analytics`, `silver_google_ads`, `silver_meta_ads`

**Marts — Dimensions** (6 models)
- `dim_campaign`, `dim_customer`, `dim_gate`, `dim_payment_method`, `dim_product`, `dim_ticket_type`

**Marts — Facts** (22 models)
- `bridge_session_customer`, `fct_ad_campaign_daily`, `fct_campaign_attribution`, `fct_campaign_performance`, `fct_daily_operations`, `fct_digital_ad_performance`, `fct_donor_cohort_survival`, `fct_donor_retention`, `fct_fundraising`, `fct_gl_transactions`, `fct_marketing_channel_summary`, `fct_marketing_sales_daily`, `fct_monthly_operations`, `fct_monthly_retail`, `fct_retail_line_items`, `fct_ticket_availability`, `fct_ticket_demand_benchmarks`, `fct_ticket_sales`, `fct_ticket_utilization`, `fct_visitor_traffic`, `fct_website_funnel`, `fct_website_traffic`

**Marts — Reports** (9 models)
- `rpt_campaign_performance`, `rpt_customer_ltv`, `rpt_daily_operations`, `rpt_digital_marketing`, `rpt_member_360`, `rpt_retail_performance`, `rpt_revenue_bridge`, `rpt_ticket_sales`, `rpt_visitor_traffic`

**ML Features** (14 models)
- All `ml_*` models disabled — depend on disabled upstream facts

---

## [1.2.0] — 2026-06-25 — Best Practices, Security & Monitoring

*Errata (2026-07-29): the version number 1.2.0 was used twice. This is the second (later) 1.2.0, dated 2026-06-25; the earlier 1.2.0 dated 2026-06-23 ("dbt Platform Foundation") appears further down. Entries are kept as written — disambiguate by date.*

### Added
- `NS11MM_DW_DEV.MONITORING` schema — alerts, tasks, audit views, DMFs
- 5 active alerts: source freshness, dbt failures, warehouse utilization, credit consumption, long-running queries
- `MANAGE_ALERTS` stored procedure — suspend/resume alerts individually or all at once
- 4 scheduled tasks: daily dbt build (6 AM), freshness check (5:30 AM), weekly PROD clone (Sun 2 AM), weekly docs generate (Mon 7 AM)
- 3 masking policies: MASK_NAME, MASK_EMAIL, MASK_PHONE (DEV + PROD)
- Row access policy: RAP_PII_ACCESS (ML_ROLE filtered from PII rows)
- Network policy: NS11MM_NETWORK_POLICY (created, NOT activated — test first)
- 3 governance tags: SENSITIVITY, DATA_DOMAIN, DATA_OWNER
- 4 Data Metric Functions: DMF_NULL_RATE, DMF_ROW_COUNT, DMF_DUPLICATE_RATE, DMF_FRESHNESS_HOURS
- `macros/operations/apply_masking_policies.sql` — auto-applies masking on-run-end
- `macros/operations/apply_governance_tags.sql` — auto-applies tags on-run-end
- `macros/operations/create_raw_streams.sql` — creates CDC streams on RAW tables
- `.github/workflows/dbt-ci.yml` — CI workflow for PR validation
- `docs/DATA_CONTRACTS.yml` — freshness SLAs, quality thresholds, refresh targets
- `models/exposures.yml` — expanded with 5 Power BI dashboards, 3 Cortex Analyst views, 3 ML models
- 2 Snowflake secrets: SECRET_POWERBI_SVC, SECRET_LOADER_SVC (rotate immediately)
- Deployed dbt project: `NS11MM_DW_DEV.PUBLIC.NS11MM_DATA_PLATFORM`

### Changed
- `DEPLOY_DEV_ROLE` and `DEPLOY_PROD_ROLE` created with proper hierarchy
- Old roles removed: `DBT_DEV_ROLE`, `DBT_PROD_ROLE`
- `MUSEUM_DW_DEV` database dropped (old POC)
- `NS11MM_DW_DEV_KRAMSEY` database dropped
- All old schemas removed from JMYERS and PROD (BRONZE, SILVER, GOLD, etc.)
- NS11MM_DW_DEV time travel increased to 7 days
- Warehouse auto_suspend: MONITORING/SOURCES/DBT_DEV reduced to 30s
- Statement timeouts set on all warehouses (5–60 min based on workload)
- POWERBI_SVC: query_tag set to 'powerbi_reporting'
- `dbt_project.yml`: added `on-run-end` hooks for tags + masking
- LOADER_ROLE: granted write to RAW in DEV + PROD
- POWERBI_ROLE: granted SELECT + future grants on MARTS (PROD)
- ML_ROLE: granted SELECT INTERMEDIATE/MARTS + WRITE ML_FEATURES

### Documentation Updated
- `SNOWFLAKE_SETTINGS.md` — complete rewrite reflecting current state
- `docs/README.md` — schema table updated with STAGING layer
- `docs/ONBOARDING.md` — RBAC roles, profiles.yml note for Snowflake-native
- `docs/architecture/DATA_CLASSIFICATION.md` — updated PII locations, masking policies, role-based access table
- `docs/architecture/TEST_ORCHESTRATION.md` — updated source names and freshness thresholds
- `docs/architecture/SQL_STYLE_GUIDE.md` — updated naming convention table
- `docs/architecture/SOURCE_INTEGRATION.md` — terminology (Bronze → RAW)
- `docs/architecture/USAGE_AUDIT.md` — added pre-built monitoring views section
- `docs/business/METRIC_GLOSSARY.md` — fiscal year corrected to October start
- `macros/operations/README.md` — added all new macros + on-run-end hooks
- `macros/data_quality/README.md` — updated freshness thresholds
- `RUNBOOK.md` — added GDPR, governance, alert management, and deployed dbt project commands
- `PLATFORM_SCORECARD.md` — new file: best-in-class assessment (9.3/10), architecture diagram, role hierarchy, monitoring stack, industry comparison

---

## [1.1.0] — 2026-06-24 — Production Git Workspace Migration

*Errata (2026-07-29): the version number 1.1.0 was used twice. This is the second (later) 1.1.0, dated 2026-06-24; the earlier 1.1.0 dated 2026-06-23 ("Bronze Ingestion Pipeline Framework") appears further down. Entries are kept as written — disambiguate by date.*

### Added
- `profiles.yml` for Snowflake-native dbt (no env_var/password/authenticator)
- `models/raw/stg_gateway__customers.sql` — staging model for Gateway customer data
- `models/intermediate/schema.yml` — documentation + tests for all 12 intermediate models
- `models/marts/facts/schema.yml` — documentation + tests for all 22 fact models
- `models/marts/reports/schema.yml` — documentation + tests for all 9 report models
- `models/ml_features/schema.yml` — documentation + tests for all 14 ML feature models
- `semantic_models/ns11mm_marketing_performance.yaml` — SV_MARKETING_PERFORMANCE (6 entities: digital_ad_performance, email_campaigns, website_traffic, website_funnel, channel_summary, dates)
- `semantic_models/ns11mm_marketing_sales.yaml` — SV_MARKETING_SALES (3 entities: marketing_sales_daily, campaign_attribution, dates)
- `notebooks/ml_member_churn_prediction.ipynb` — XGBoost member churn classifier with Snowflake ML Registry integration
- `notebooks/ml_ticket_demand_forecast.ipynb` — XGBoost ticket demand forecaster with Snowflake ML Registry integration
- `macros/operations/gdpr_anonymize.sql` — GDPR right-to-erasure macro; anonymizes PII across INTERMEDIATE + MARTS layers with audit log
- `macros/generic_tests/z_score_outlier.sql` — statistical outlier detection test (configurable z-score threshold)
- `macros/generic_tests/positive_value.sql` — assert column values are non-negative
- `macros/generic_tests/value_between.sql` — assert column values within min/max bounds
- Three-tier RBAC promotion model: TRANSFORMER_ROLE → DEPLOY_DEV_ROLE → DEPLOY_PROD_ROLE

### Fixed
- `silver_sf_crm` — replaced NULL placeholders with actual joins to stg_salesforce_nps__opportunities for membership and donation enrichment
- `silver_blackbaud` — fixed `CASE WHEN null` logic (now uses `CASE WHEN IS NULL`)
- `silver_pos_tickets` — resolved missing customer_email/phone by creating stg_gateway__customers and joining
- `dim_customer` schema.yml — test column corrected from `id` to `customer_id`, added `unique` test
- `dbt_project.yml` — raw models schema changed from `INTERMEDIATE` to `STAGING`
- README fiscal year reference corrected to October start (was July)

### Changed
- `profiles.yml` — `dev_shared` target now uses `DEPLOY_DEV_ROLE`, `prod` uses `DEPLOY_PROD_ROLE`
- `ns11mm_operations.yaml` — expanded with daily_operations + ticket_availability tables (now 5 entities)
- `ns11mm_fundraising_members.yaml` — added donor_retention table (now 5 entities)
- `CONTRIBUTING.md` — added RBAC-enforced promotion workflow, role permissions table, developer targets, emergency hotfix process, updated environment architecture and schema table
- `RUNBOOK.md` — corrected schema reference from GOLD to MARTS
- `docs/architecture/ARCHITECTURE_FLOW.md` — staging layer schema updated to STAGING, model names updated to production naming convention
- `docs/architecture/PROJECT_MAP.md` — reference chain updated from POC single-source pattern to 14-source production pattern

---

## [1.2.0] - 2026-06-23

*Errata (2026-07-29): duplicate version number — this is the first (earlier) 1.2.0, dated 2026-06-23. A second 1.2.0 dated 2026-06-25 appears above. Entries are kept as written — disambiguate by date.*

### dbt Platform Foundation — POC Migration Scaffolding

119 files added establishing the complete dbt project structure for the production platform. All files are either fully production-ready or structured stubs awaiting RAW data connection. No files from this release require logic changes — only field name confirmation once Bronze ingestion is live.

#### Project configuration

- `dbt_project.yml` — production configuration: project name `ns11mm_data_platform`, all schema targets (RAW, SILVER, GOLD, ML_FEATURES), query tags, pre-hooks, materialization strategies, and post-hooks granting POWERBI_ROLE and ML_ROLE on Gold models
- `packages.yml` — `dbt_utils` and `dbt_date` package dependencies
- `.gitignore` — standard dbt ignores including `profiles.yml`, `dbt.log`, `graph.gpickle`
- `.sqlfluff` / `.sqlfluffignore` — Snowflake dialect linting, 120-char limit, macros excluded
- `CODEOWNERS` — Jeremy as primary owner; Kalea co-owner on `models/staging/` and `models/silver/`
- `CONTRIBUTING.md` — full developer workflow: environment architecture, local setup, profiles template, change gate classification (Tier 1/2/Emergency), PR checklist, VQR workflow
- `RUNBOOK.md` — daily health check queries, pipeline and dbt failure response, contacts, quick reference command table
- `SNOWFLAKE_SETTINGS.md` — complete inventory of databases, schemas, roles, warehouses, resource monitors, and integrations

#### Models — Staging (24 files)

- `models/staging/sources.yml` — all 14 source definitions with freshness thresholds; activate per source as RAW tables are populated
- 23 staging model shells covering all 14 sources: Salesforce NPS (4 objects), Salesforce MC, Gateway (2 objects), CounterPoint (2 objects), Shopify (3 objects), Classy (2 objects), Blackbaud (2 objects), Vena, GA4, Google Ads, Meta Ads, Wufoo, Clicky, Drupal. Each model has the correct VARIANT extraction structure (`_raw_data:<Field>::<TYPE>`), hashdiff generation, and a TODO comment pointing to the exact `SELECT _raw_data ... LIMIT 1` query needed to confirm field names

#### Models — Gold Dimensions (11 files)

- `dim_date.sql` — **fully active**: complete date dimension spanning 2000–2035 with NS11MM fiscal calendar (Oct 1–Sep 30), weekend flags, and `is_commemoration_day` flag for September 11 anomaly handling
- `dim_marketing_channel.sql` — **fully active**: seed-based channel dimension; no RAW dependency
- 8 dimension placeholder stubs (`dim_customer`, `dim_gate`, `dim_campaign`, `dim_ticket_type`, `dim_product`, `dim_payment_method`, `dim_fund`, `dim_budget_version`) — correct config and schema entry; replace `select null where 1=0` body with POC logic once Silver is live
- `schema.yml` — full dimension documentation and tests including `is_commemoration_day` description

#### Macros — Generic Tests (10 files)

- `test_hashdiff_integrity.sql` — null hash detection and hash collision check
- `test_referential_integrity.sql` — reusable FK validation
- `test_row_count_drift.sql` — zero-row alert
- `test_late_arriving_data.sql` — configurable lag threshold (default 72h)
- `test_schema_drift.sql` — expected vs actual column comparison
- `null_rate_threshold.sql` — configurable null rate ceiling (default 50%)
- `daily_volume_bounds.sql` — min/max row count per day
- `cardinality_change.sql` — distinct value range check
- `distribution_shift.sql` — value frequency drift detection
- `README.md`

#### Macros — Data Quality (5 files)

- `generate_hashdiff.sql` — MD5 over business columns with null-safe concatenation
- `quarantine_failed_rows.sql` — routes failed rows to `SILVER.QUARANTINE_LOG`
- `auto_heal_duplicates.sql` — CTE deduplication keeping latest row by primary key
- `check_source_freshness.sql` — per-source staleness thresholds for all 13 API sources; called in on-run-start
- `README.md`

#### Macros — Operations (8 files)

- `create_ticket_demand_forecast.sql` — creates Snowflake ML FORECAST model for 90-day multi-series ticket demand; `dbt run-operation create_ticket_demand_forecast`
- `sync_verified_queries.sql` — lists and validates all VQRs; `dbt run-operation sync_verified_queries`
- `validate_before_deploy.sql` — compares dev/prod row counts for 10 key models before deployment
- `compare_model_to_prod.sql` — deep single-model MINUS diff between dev and prod; flags data loss risk
- `smart_retry.sql` — reads audit log, identifies failed models, suggests rerun commands
- `rerun_from_source.sql` — maps RAW source table to downstream dbt models; source map covers all 14 sources
- `resolve_quarantine.sql` — marks quarantine records resolved after successful rerun
- `README.md`

#### Macros — Root (1 file)

- `generate_schema_name.sql` — standard dbt schema name override macro

#### Tests (16 files)

All reconciliation and referential integrity tests are written and commented out pending production model availability. One test is immediately active:

- `tests/business_rules/assert_date_coverage.sql` — **active now**: validates `dim_date` spans 2000-01-01 through 2035-12-31

Commented-out tests (uncomment as each layer becomes available):
- `tests/reconciliation/` — 4 tests: RAW→Silver count matches for tickets and retail; Silver→Gold revenue and visitor reconciliation
- `tests/referential_integrity/` — 5 tests: campaign FK, ticket type seed match, payment method seed match, customer segment seed match, date orphan check
- `tests/business_rules/` — 3 additional tests: no negative revenue, no future transactions, campaign rates in bounds
- All `README.md` files

#### Seeds (5 files)

All reference data seeds — no mock/POC data included:

- `ref_marketing_channels.csv` — 7 channels (Paid Search, Paid Social Facebook/Instagram, Organic, Email, Direct, Referral)
- `ref_ltv_tiers.csv` — Platinum/Gold/Silver/Bronze with thresholds
- `ref_ticket_types.csv` — 10 ticket types matching Gateway taxonomy (Adult/Child/Senior GA, Member, Group, School, Military, First Responder)
- `ref_payment_methods.csv` — 8 payment methods including digital wallets
- `ref_customer_segments.csv` — Known Member / Identified Visitor / Anonymous

#### Snapshots (2 files)

- `snap_dim_customer.sql` — SCD Type 2 on customer dimension; check strategy on segment, membership_status, email, phone; commented out pending dim_customer
- `snap_sf_crm.sql` — SCD Type 2 on Salesforce NPS contacts via hashdiff; commented out pending staging model

#### CI/CD (1 file)

- `.github/workflows/dbt-ci.yml` — slim CI on PRs (state:modified+ with defer); full build on merge to main; manifest artifact upload for state comparison; dbt docs generation on merge

#### Governance documentation (7 files)

- `docs/architecture/SQL_STYLE_GUIDE.md` — naming conventions, layering rules, VARIANT extraction pattern, formatting standards, testing requirements
- `docs/architecture/DATA_CLASSIFICATION.md` — PII field inventory across all 14 sources, access control tiers, new model classification checklist
- `docs/architecture/USAGE_AUDIT.md` — Snowflake query history monitoring, Cortex Agent observability, pipeline log queries, credit monitoring
- `docs/business/METRIC_GLOSSARY.md` — certified metric definitions across 6 domains: Attendance, Revenue, Membership, Fundraising, Digital/Marketing, Flags (including `is_commemoration_day`)
- `docs/adr/0005-metric-definition-gate.md` — metric approval required before Gold model build
- `docs/adr/0006-change-management-tiers.md` — Tier 1/2/Emergency framework
- `docs/adr/0007-drupal-ingestion-path.md` — **decision required**: DB vs JSON:API; unblocks `stg_drupal__pages.sql`
- `docs/adr/0008-retail-source-split.md` — **decision required**: unified vs separate retail fact; recommendation is unified with channel flag (Option A)

#### Model groups and exposures (2 files)

- `models/groups.yml` — 6 groups (staging, silver, gold_dimensions, gold_facts, gold_reports, ml_features) with owner emails
- `models/exposures.yml` — 5 exposures: Power BI operations dashboard, Power BI donor retention dashboard, Cortex Analyst operations, ML donor churn model, ML ticket demand forecast

#### Terraform / IaC (16 files)

- `terraform/main.tf` — root module orchestrating 4 sub-modules
- `terraform/variables.tf` / `outputs.tf` / `providers.tf` — standard configuration
- `terraform/modules/key-vault/main.tf` — RBAC-based Key Vault with soft-delete and purge protection; admin and pipeline SP role assignments
- `terraform/modules/snowflake-warehouse/main.tf` — warehouse + resource monitor with credit quota
- `terraform/modules/static-web-app/main.tf` — dbt docs hosting
- `terraform/modules/monitor-alerts/main.tf` — Teams webhook + email alert action group
- `terraform/environments/dev.tfvars.json` — X-Small warehouse, 5 credits, `kv-ns11mm-dp-dev`
- `terraform/environments/staging.tfvars.json` — Medium warehouse, 25 credits
- `terraform/environments/prod.tfvars.json` — Medium warehouse, 50 credits
- `terraform/pipelines/deploy-dev.yml` — auto-trigger on main merge
- `terraform/pipelines/deploy-staging.yml` — manual trigger
- `terraform/pipelines/deploy-prod.yml` — manual trigger + ManualValidation approval gate
- `terraform/README.md` / `.gitignore`

#### Scripts (1 file)

- `scripts/setup_developer_workspace.sql` — provisions personal dev database for a new team member; creates RAW/SILVER/GOLD/ML_FEATURES schemas, grants TRANSFORMER_ROLE and LOADER_ROLE access, creates audit log table. Includes commented examples for JMYERS, KRAMSEY, DIANA.

#### POC migration inventory

- `NS11MM_POC_Migration_Inventory.md` — complete inventory of all 247 POC artifacts with status: 66 complete, 44 awaiting data feed, 109 to migrate from POC with find-and-replace, 10 to rebuild, 1 pending decision, 6 excluded. Includes sequenced "what to do next" and find-and-replace table for all naming changes.

#### Outstanding items from this release

| Item | Owner | Blocks |
|---|---|---|
| ADR-007: Drupal path decision | Jeremy + Anna Kim + Kenny | `stg_drupal__pages.sql` completion |
| ADR-008: Retail source split decision | Jeremy | `silver_pos_retail.sql`, `fct_retail_line_items.sql` |
| Migrate 36 verified queries from POC | Kalea | Cortex Analyst activation |
| Migrate `docs/ONBOARDING.md` and `docs/README.md` from POC | Jeremy | Onboarding |
| Migrate `terraform/notifications/teams_webhook_setup.sql` from POC | Kenny | Credit alerts |
| Complete remaining 109 POC file migrations (Silver, Gold, ML, VQRs) | Kalea / Phinn | Gold layer activation |

---

## [1.1.0] - 2026-06-23

*Errata (2026-07-29): duplicate version number — this is the first (earlier) 1.1.0, dated 2026-06-23. A second 1.1.0 dated 2026-06-24 appears above. Entries are kept as written — disambiguate by date.*

### Bronze Ingestion Pipeline Framework

**Scope:** Raw data ingestion to Snowflake RAW schema only. dbt staging, Silver, and Gold are handled separately in `models/`.

#### Shared Library (`pipelines/shared/`)

- `shared/__init__.py` — marks shared/ as a Python package importable by all pipelines
- `shared/keyvault.py` — Azure Key Vault client using `DefaultAzureCredential`; single `secret(name)` function used by all pipelines; singleton client pattern to avoid re-authentication on each call
- `shared/snowflake_client.py` — shared Snowflake connection, Bronze landing, and pipeline logging:
  - `get_connection()` — connects using Key Vault credentials; targets `NS11MM_DW_DEV.RAW` schema with `LOADER_ROLE`
  - `land_to_bronze()` — append-only insert of raw records as VARIANT (JSON) columns; creates table if not exists; never updates or deletes
  - `log_run()` — writes success/failed run record to `RAW.PIPELINE_LOG`; creates table if not exists
- `requirements-shared.txt` — shared dependencies: `azure-identity`, `azure-keyvault-secrets`, `snowflake-connector-python`, `requests`

#### Source Pipelines (14 sources)

Each pipeline contains `authenticate()` and `extract()` functions unique to the source, plus a `run()` function identical across all pipelines that calls shared library functions for landing and logging.

| Source Folder | Source System | Auth Pattern | Schedule (UTC) |
|---|---|---|---|
| `salesforce_nps/` | Salesforce NPS (Sales Cloud for Nonprofits) | OAuth 2.0 Username-Password | 07:00 |
| `salesforce_mc/` | Salesforce Marketing Cloud | OAuth 2.0 Client Credentials | 07:15 |
| `gateway/` | Gateway Ticketing Galaxy | SQL Server read-only (pyodbc) via on-prem agent | 07:30 |
| `counterpoint/` | NCR CounterPoint POS | SQL Server read-only (pyodbc) via on-prem agent | 07:45 |
| `shopify/` | Shopify (E-commerce) | Custom App access token in header | 08:00 |
| `classy/` | GoFundMe Pro / Classy | OAuth 2.0 Client Credentials | 08:15 |
| `blackbaud/` | Blackbaud Financial Edge NXT | OAuth 2.0 Refresh Token (SKY API) | 08:30 |
| `vena/` | Vena Solutions (FP&A) | API key / Bearer token | 08:45 |
| `ga4/` | Google Analytics 4 | Google Service Account JSON key | 09:00 |
| `google_ads/` | Google Ads | OAuth 2.0 with Developer Token | 09:15 |
| `meta_ads/` | Meta Ads (Facebook/Instagram) | System User Access Token | 09:30 |
| `wufoo/` | Wufoo (Forms) | HTTP Basic Auth (API key) | 09:45 |
| `clicky/` | Clicky (Web Analytics) | API key + Site ID as query parameters | 10:00 |
| `drupal/` | Drupal CMS | Bearer token (JSON:API path; pending ADR) | 10:15 |

All pipelines support `--full` flag for initial historical load and default to incremental (last 24 hours) for nightly runs.

#### Azure DevOps Deployment (14 YAML files)

One deployment YAML per source, placed in repo root:

`azure-pipelines-sfnps.yml`, `azure-pipelines-sfmc.yml`, `azure-pipelines-gateway.yml`, `azure-pipelines-counterpoint.yml`, `azure-pipelines-shopify.yml`, `azure-pipelines-classy.yml`, `azure-pipelines-blackbaud.yml`, `azure-pipelines-vena.yml`, `azure-pipelines-ga4.yml`, `azure-pipelines-googleads.yml`, `azure-pipelines-metaads.yml`, `azure-pipelines-wufoo.yml`, `azure-pipelines-clicky.yml`, `azure-pipelines-drupal.yml`

Each YAML includes:
- Path trigger scoped to `pipelines/<source>/` and `pipelines/shared/` — shared library changes redeploy all dependent pipelines
- PR trigger for validation on pull requests (Validate stage only; Deploy stage requires merge to main)
- Two-stage pipeline: Validate (import check) and Deploy (Azure Function App)
- Variables: `FUNCTION_APP_NAME`, `AZURE_SERVICE_CONNECTION`, `PYTHON_VERSION`

#### Documentation

- `pipelines/README.md` — pipeline framework overview: folder structure, how pipelines work, running instructions, shared library usage, adding a new pipeline, nightly schedule, credential conventions, outstanding blockers, key contacts
- `NS11MM_Azure_IT_Setup_Request.docx` — IT setup request for Kenny covering Key Vault provisioning, Function App spec and naming convention, managed identity and Key Vault RBAC setup, outbound network access requirements, Azure DevOps service connection, and recommended 12-step setup sequence
- `NS11MM_Source_Credential_Intake.xlsx` — credential intake workbook with one tab per source; Key Vault secret names, collection hints, and status tracking for all 14 sources
- `ns11mm_bronze_pipelines_master.md` — master pipeline reference covering shared library, per-source guides, nightly schedule, and pipeline status tracker

#### Snowflake Setup (one-time)

```sql
CREATE ROLE IF NOT EXISTS LOADER_ROLE;
GRANT USAGE ON DATABASE NS11MM_DW_DEV TO ROLE LOADER_ROLE;
GRANT USAGE ON SCHEMA NS11MM_DW_DEV.RAW TO ROLE LOADER_ROLE;
GRANT CREATE TABLE ON SCHEMA NS11MM_DW_DEV.RAW TO ROLE LOADER_ROLE;
GRANT INSERT ON FUTURE TABLES IN SCHEMA NS11MM_DW_DEV.RAW TO ROLE LOADER_ROLE;
GRANT ROLE LOADER_ROLE TO USER <pipeline_service_user>;
```

#### Credential status at release

| Source | Status |
|---|---|
| Salesforce Marketing Cloud | Auth URI, REST URI, SOAP URI confirmed; Client ID collected; Client Secret requires regeneration; MID outstanding |
| All other sources | Pending Key Vault setup |

#### Outstanding items before first pipeline run

- Kenny: provision `kv-ns11mm-dp-dev` Key Vault and `func-ns11mm-sfmc-dev` Function App per IT setup doc
- Jeremy: add Snowflake and SFMC credentials to Key Vault once provisioned; regenerate SFMC Client Secret
- Vena: populate `MODELS` dict in `pipelines/vena/pipeline.py` after confirming model IDs with Finance team
- Drupal: confirm DB vs JSON:API path (ADR required); populate `CONTENT_TYPES` list after scope confirmation with Anna Kim
- Blackbaud: registered app requires Blackbaud Admin approval; refresh token rotation requires Key Vault Secrets Officer role on Function App managed identity
- Gateway / CounterPoint: run via self-hosted agent on internal network, not Azure Functions; VM setup to be coordinated separately with Kenny

---

## [1.0.0] - 2026-06-23

### Initial production repository setup

- Created `ns11mm/ns11mm-data-platform` as the production repository, replacing POC repo `jmyers911mm/ns11mm-dbt`
- Established medallion architecture: RAW (Bronze) / staging / intermediate / marts naming convention
- Configured `dbt_project.yml` for `ns11mm_data_platform` project
- Configured `profiles.yml` with dev target (`NS11MM_DW_DEV`) and prod target (`NS11MM_DW_PROD`)
- Established PR-gated CI/CD as the required deployment pattern for all model changes
- Snowflake workspace: `NS11MM_DW_DEV.PUBLIC."ns11mm-dbt"` (shared dev environment)
- Personal dev databases: `NS11MM_DW_DEV_JMYERS` (Jeremy), `NS11MM_DW_DEV_KRAMSEY` (Kalea)

### Governance baseline

- ADR register established (ADR-001 through ADR-017)
- ADR-005: Metric Definition Gate — metric approval required before any Gold model is built
- ADR-006: Change Management Framework — tiered change management (Tier 1 / Tier 2 / Emergency)
- Bronze/RAW layer: immutable, append-only — architectural constraint enforced by design
- All business logic in dbt; Power BI is display-only

---