# 8.11.0: Earned Income Variance Report

- **Date:** 2026-08-12
- **Version:** 8.11.0

Migrates the last uncovered live report in the estate, and the highest-exposure one: a
thirteen-sheet XLSX that goes to the CFO and the finance leadership group. Purely additive —
eighteen new files, **no repo file edited** — so no number that exists today moves. Not
itself ADR-005 gated, but **it must not be promoted ahead of 8.5.0 → 8.8.0**: all nineteen of
its printed lines re-project the models those releases correct, so shipping it early
publishes pre-gate figures to the CFO and then restates them. 8.8.0 is load-bearing in
particular — Early Access and Youth & Family have actuals only because of it, and this is the
first surface that prints them.

## Added

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

## Why there is no `*_powerbi` wrapper, `*_period_windows` or `*_print` model

ADR-021 makes the wrapper the only caller of `SEMANTIC_VIEW()`, and this release adds no
`EARNED_INCOME` semantic view, so a wrapper would be a lie about where the metric definitions
live; the serving shape reads the mart fact directly, the path `rpt_carts_report_long` and
`rpt_retail_analysis_report_long` already take. The workbook prints day rows inside a year
sheet rather than six period columns, so `_period_windows` has no analogue and none was
invented. The legacy Excel writer is a raw dump of one query into thirteen sheets with no row
catalog of its own, so the layout seed plus the line-item dimension is the whole presentation
contract.

## Deliberate seams (not moves)

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

## Findings recorded in the caveats tables (no code change this release)

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
