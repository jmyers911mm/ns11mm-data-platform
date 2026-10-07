# 7.12.4: Retail Performance Printed Grid (PDF-faithful rows)

- **Date:** 2026-08-07
- **Version:** 7.12.4

Reading the legacy PDF closely showed the report prints **scenario as ROWS**, not columns:
each metric appears as a '... Goal' row and a '... Actual' row, with a shaded 'Variance'
row on selected metrics only, and the six periods as the only columns. Every prior spec
(and the Power BI guidance built on it) assumed scenario-as-columns. This release encodes
the printed layout in the platform so Power BI needs one measure and no scenario switch.

## Added

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

## Changed

- **`rpt_retail_period_windows`** accepts an optional `retail_as_of_date` var to pin the
  anchor for reconciliation against a specific legacy PDF:
  `dbt build --select rpt_retail_period_windows+ --vars '{retail_as_of_date: "2026-07-28"}'`.
  Unset in scheduled runs, so the anchor follows the data.

## Known layout deltas (documented, not defects)

- **Medallion Machine** has no facility mapping in `seed_facility_area`; its three rows are
  Stub/NULL (the PDF prints $0/$0/0). Confirm the CounterPoint store → facility mapping and
  the rows light up with no report change.
- **Museum Cafe Donation Ask Variance** prints $0 on the legacy report across all periods
  even where actual is non-zero and goal is $0; this build computes actual − goal. Confirm
  whether the legacy $0 is intentional before matching it.
- **Memorial Carts donations** label asymmetry ('Donations Goal' / 'Donation Ask Actual') is
  reproduced verbatim from the PDF.
