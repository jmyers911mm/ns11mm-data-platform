# 8.6.0: Gateway Admissions Correctness

- **Date:** 2026-08-12
- **Version:** 8.6.0

**ADR-005 gated. This release must not ship before sign-off from Chris Wogas** (admissions and
ticketing definitions) **and Mary Ng-Zuffante** (revenue recognition and the finance-facing
totals), per `DECISION_MEMO.md`. Six of its seven changes move a number that appears on the
printed Daily Performance Report, the MTD/YTD workbooks, or both. Items 1, 2, 4 and 5 all feed
`ADMISSION_REVENUE`, so a partial acceptance produces a total that matches neither the legacy
report nor the current one; the memo asks for them as one decision. Cumulative on 8.1.0, which
ships without a gate.

## Added

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

## Changed

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

## Numbers that move

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

## Findings recorded in the caveats tables (no code change this release)

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
