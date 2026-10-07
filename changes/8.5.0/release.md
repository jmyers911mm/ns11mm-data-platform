# 8.5.0: Ratio Definitions (capture ≠ conversion)

- **Date:** 2026-08-12
- **Version:** 8.5.0

**ADR-005 gated. This release must not ship before sign-off from Gennady Zaritsky and Chris
Wogas**, per `DECISION_MEMO.md`. It changes what two certified rates report. Three changes,
all of which were one defect wearing three hats: the platform had collapsed two metrics into
one. Depends on 8.4.0 and carries a cumulative `fct_retail_daily.sql`.

## Added

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

## Changed

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

## Numbers that move

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

## Findings recorded in the caveats tables (no code change this release)

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
