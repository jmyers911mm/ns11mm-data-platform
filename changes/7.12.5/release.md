# 7.12.5: DPR MTD / YTD / Excel Data Serving (reports 2–4)

- **Date:** 2026-08-10
- **Version:** 7.12.5

Finishes the three DPR variants. Correcting an earlier claim in the build notes: these are
NOT DAX variants of the daily DPR stack. The MTD/YTD workbooks print a different, longer
line-item set (~61 printed rows vs dpr_line_items' 28), compare ACTUAL to PRIOR YEAR rather
than to budget, break donations out individually, and print retail sub-metrics the DPR fact
does not carry. DPR Excel Data prints area REVENUE where the other reports print gross
PROFIT.

## Added

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

## Changed

- **`rpt_dpr_powerbi`** projects 18 additional metrics that were already authored in the DPR
  semantic view but never surfaced: service fees, mask donations, memorial audio guide,
  ask-educator revenue, total retail gross profit, total donations, audio headset units, the
  four field-trip count/revenue pairs, and the virtual memorial/museum/YF tour counts and
  revenues. No semantic-view or DDL change was needed — the metrics existed.

## Verified against the 2025-12-31 workbooks (to the cent)

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

## Open items

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
