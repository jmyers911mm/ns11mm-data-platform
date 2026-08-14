# Pre-Decommission Recovery Checklist

**Deadline: before the Pentaho server and the `911dw` MySQL estate are decommissioned
(5 January 2027).**

Everything on this list is logic or data that is *not* in `legacy_sql/` or
`legacy_report_sql/` and cannot be reconstructed from them. Each item is either missing from
the repository export, held in a stored procedure, held in a manual workbook, or resolvable
only by querying the legacy warehouse while it still exists.

This is the one piece of v8 with a hard external deadline. Nothing else in the series is
harder to do later; this is *impossible* later.

Owner column names the person who can answer, not necessarily who runs the query.

---

## A. Missing from the repository export — pull the `.ktr` files

Seven transformations are called by job definitions but are absent from
`Pentaho/Transformations/`. Five are on live paths.

| # | Transformation | Called by | Feeds | Live? | Owner |
|---|---|---|---|---|---|
| A1 | `t_fact_museum_passes_issued_unissued_DSR` | `j_run_daily_scan_report_transformations` | Daily Scan Report | **yes** | Jeremy Myers |
| A2 | `t_fact_museum_passes_scanned_DSR` | same | Daily Scan Report | **yes** | Jeremy Myers |
| A3 | `t_fact_valid_invalid_passes_by_hour` | same | Daily Scan Report | **yes** | Jeremy Myers |
| A4 | `t_fact_profit_from_retail` | `j_run_dashboard_jobs` | `fact_profit_from_retail` → Monthly Retail KPI, Retail Analysis | **yes** | Jeremy Myers |
| A5 | `t_fact_calculate_dates_refresh` | 4 refresh jobs | DPR issued/unissued refresh window | **yes** | Jeremy Myers |
| A6 | `t_fact_museum_tickets_unissued_refresh_new` | `j_run_refresh_unissued_fordate_new` | DPR unissued | yes | Jeremy Myers |
| A7 | `t_fact_mus_tickets_mem_tour_unissued_fordate_new` | `j_run_museum_gateway_tickets_new` | DPR tours | yes | Jeremy Myers |

**A1–A3 matter most.** Three of the four Daily Scan Report ETL steps are missing, and the
report's other two inputs are stored procedures (§B). The Daily Scan Report's logic is
almost entirely outside this capture. Release 8.7.0 reconstructs the scan validity rule from
`t_fact_museum_passes_scanned` — a *different* transformation — and that reconstruction cannot
be checked against the DSR-specific variants until these are recovered.

**Action:** export from the Pentaho repository browser, or from the filesystem under
`/opt/pentaho/`. Drop into `legacy_sql/` via `parse2.py` and re-run `closure2.py`.

---

## B. Stored procedures — script them out of Gateway

Two live procedures on the Gateway SQL Server (`Galaxy1`) have no dbt reimplementation and no
definition in this capture.

| # | Procedure | Called by | Feeds | Owner |
|---|---|---|---|---|
| B1 | `report.fe_dailyScan_ss` | `t_fact_dailyscan_data` | Daily Scan Report | Ravi Nagaraja |
| B2 | `report.fe_dailyScan_sh` | `t_fact_passes_by_hour` | Daily Scan Report, Daily Attendance Report | Ravi Nagaraja |

`report.marketSegment` is deliberately **not** on this list — it was called only by
`t_fact_tickets_sold_dsr`, which is retired. Note that this makes the Daily Scan Report's
market-segment classification an open question in its own right: release 8.7.0's segment
mapping is inferred, and B1/B2 are the only remaining authority on it.

**Action:** `sp_helptext` or SSMS script-out, committed to `legacy_sql/stored_procedures/`.
Also capture `report.maint_decode` contents (a config table, not a procedure) if cheap —
it holds the visitor-estimate multiplier, which is retired but cheap to keep.

---

## C. Manual workbooks — take a copy and find the owner

Eight live `ExcelInput` steps read workbooks off the Pentaho filesystem. Three have dbt seed
equivalents; five do not. When the server goes, so do the files.

| # | Workbook | Loads | Seed equivalent | Owner |
|---|---|---|---|---|
| C1 | `/opt/pentaho/budgets/AdmissionDailies.xlsx` | `fact_dpr_forecasts` | `SEED_DPR_FORECASTS` ✅ | ??? |
| C2 | `/opt/pentaho/budgets/RetailDailies.xlsx` | `fact_retail_forecasts` | `SEED_RETAIL_FORECASTS` ✅ | Gennady Zaritsky |
| C3 | `/opt/pentaho/budgets/DailyScanDailies.xlsx` | `fact_dsr_forecasts` | `seed_dsr_budget` ✅ | Chris Wogas |
| C4 | `/opt/pentaho/budgets/BudgetedExpensesDailies.xlsx` | `fact_budgeted_expenses` | **none** — contract shipped empty in 8.11.0 as `seed_budgeted_expense.csv` | **unowned — see 8.11.0 DECISION_MEMO** |
| C5 | `/opt/pentaho/budgets/CityPASSTicketPrices.xlsx` | `dim_citypass_revenue` | **none** | Chris Wogas |
| C6 | `/opt/pentaho/bulk_tickets_excel/BulkTicketsPrice.xlsx` | `dim_bulk_tickets_revenue` | **none** | Chris Wogas |
| C7 | `/opt/pentaho/additional_revenue/DprAdditionalRevenue.xlsx` | `fact_additional_revenue` | **none** | Mary Ng-Zuffante |
| C8 | same workbook | `fact_civic_programs_even_space` | **none** | Mary Ng-Zuffante |

C5–C8 are **price and rate tables, not budget comparisons** — they feed revenue
calculations. C4 feeds the Earned Income Variance Report, which goes to the CFO.

**Action:** copy all eight to a governed location now; resolve ownership separately.

---

## D. Resolve-by-query — run these against `911dw` before it goes

Each of these is a specific question a v8 release could not answer from the SQL alone, where
the answer is sitting in the legacy warehouse today.

| # | Question | Blocks | Release | Owner |
|---|---|---|---|---|
| D1 | `dim_item_descr` surrogate keys → item descriptions. Needed: `2449`–`2454`, `4636`, `5095`, `5096`, `482`, `485`, `2168`–`2173`, `3373`, `3753`, `5156`, `5179`, `583`, `598`, `931` | Retail Analysis water carve-out and exclusion list; six Donations Analysis lines | 8.9.0, 8.10.0 | Gennady Zaritsky |
| D2 | `dim_galaxy_items`: `key_museum_category` → PLU crosswalk | Category-keyed buyout add-back; `TOUADDREV002` attribution; 13 excluded virtual-tour categories | 8.8.0 | Chris Wogas |
| D3 | Does anything write `911dw.memorial_attendance`? If not, where has memorial attendance been coming from? | Memorial attendance is a typed NULL; 4 layout rows `Stub` | 8.7.0 | Chris Wogas |
| D4 | Does anything write `911dw.cafe_performance` or `911dw.medallion_machine`? | Tracker cafe + medallion profit; EIV total estimated revenue | 8.10.0, 8.11.0 | Gennady Zaritsky |
| D5 | `t_reporting_mus_guided_tours_revenue` `InsertUpdate` field map — does `guided_tours` double-count `buyout_qty`? | Suspected legacy double count; 8.11.0 declined to reproduce it | 8.11.0 | Chris Wogas |
| D6 | Do `MUSGADADCP005` / `MUSGADYSCP005` carry a `GAD` matrix code? | Decides whether pass revenue *gains* those dollars or *takes them from* ticket revenue | 8.6.0 | Chris Wogas |
| D7 | Reseller identities for customer ids `17522`, `23110`, `22361` | Documentation of the reseller split; the split itself is implemented | 8.6.0 | Chris Wogas |
| D8 | Has `CPBOOKAD008` / `CPBOOKYS008` ever been excluded? (legacy has `'CPBOOKAD008''CPBOOKYS008'` — a missing comma, so SQL Server parsed one literal) | Reading it as intended removes long-standing dollars | 8.6.0 | Chris Wogas |
| D9 | `pricePointID = 84` child-ticket subtraction — which table carries it? | Tickets sold; currently a typed NULL feed gap | 8.6.0 | Chris Wogas |
| D10 | `key_coupon_category` values for CityPASS Adult/Youth | CityPASS revenue `quantity * amount` extension; 1 layout row `Partial` | 8.11.0 | Chris Wogas |

Queries for D1, D5 and D6 are written out in the relevant release `NOTES.md`.

---

## E. Not recoverable, record the fact

| # | Item | Note |
|---|---|---|
| E1 | Job schedules | Cron lives in the Pentaho scheduler, not the `.kjb` files. Read the cadences off the server and record them in the ADR-011 appendix, which is currently marked `[confirm]`. |
| E2 | Sensource API chain | Six `SSH` steps invoking remote scripts. The logic is on another host entirely. Capture the scripts or accept the loss. |
| E3 | Distribution lists | 113 `MAIL` entries are captured in `pentaho_parsed.json`, but the `@911memorial.org` group aliases (`earnedincomereports@`, `donationanalysis@`, `musattendance@`, `vsrevenuereport@`, `membershipreport@`) expand in Exchange. Export the memberships — they are the go-live distribution list for Power BI subscriptions. |
| E4 | `.prpt` layout | `legacy_report_sql/` captures the queries, not the page layout, fonts, grouping or conditional formatting. The rendered PDFs in `Pentaho/Reports/ops_reports/` are the only record of appearance; keep them. |

---

## Suggested order

1. **§A and §B** — pure export, no analysis, and A1–A3 gate any real verification of the
   Daily Scan Report.
2. **§C** — copy the files today; ownership can be settled afterwards.
3. **§D** — needs a person who knows the business, so it takes longest to schedule. Start
   booking it now.
4. **§E** — cheap, do it alongside §C.
