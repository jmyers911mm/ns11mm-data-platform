# 8.1.0: Dead Code & Double Counts

- **Date:** 2026-08-12
- **Version:** 8.1.0

Not gated. Nothing here redefines a certified metric on the basis of a judgement call: every
change is either code that provably does nothing today, or a component counted twice, or two
surfaces of the same report disagreeing with each other and with the legacy definition of
record. Items 4 and 5 below do move published numbers; they are included because the
pre-change state is internally contradictory, not because a definition was chosen, and each
carries its exact delta and the query that measures it.

## Changed

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

## Removed

- **`rpt_attendance`'s dead Sensource columns.** `sensource_mem_attendance` /
  `sensource_mus_attendance` were selected into a CTE and never projected — recorded in the
  7.13.1 CHANGELOG, still true. They are removed rather than surfaced deliberately: the report
  already publishes `memorial_attendance` / `museum_attendance` from `fct_daily_performance`,
  and adding a second, differently-sourced attendance pair beside them would ship the
  Sensource-blend ambiguity to report consumers before ADR-005 has settled it (owner: Chris
  Wogas). **Numbers moved: none** — the columns were never in the output.

## Fixed (stale documentation, not code)

- **`rpt_memorial_museum_tracker_ytd`'s `cafe1_donations` comment.** It claimed the column was
  "not surfaced in `fct_daily_performance` yet"; it has been for some time
  (`fct_daily_performance` line 127). The gap in `total_donations_ytd` is real, but its cause
  is a component choice, not a missing upstream column. The note is corrected here (free) and
  the fix is carried into the 8.6.0 memo (gated). **Numbers moved: none.**

## Findings recorded in the caveats tables (no code change this release)

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
