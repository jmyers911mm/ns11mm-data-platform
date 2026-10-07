# 8.8.0: Tour Buyout & Unissued Revenue

- **Date:** 2026-08-12
- **Version:** 8.8.0

**ADR-005 gated. This release must not ship before sign-off from Chris Wogas**, the metric
owner, per `DECISION_MEMO.md`. Cumulative on 8.7.0; **both releases must be signed before
either is promoted**. Two whole legs of DPR revenue recognition were missing from the
platform: the legacy DPR builds each tour and admission line by adding issued journal lines,
unissued order lines and buyout lines together, and the platform carried only the first.

## Added

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

## Changed

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

## Numbers that move

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

## Findings recorded in the caveats tables (no code change this release)

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
