# Report → Semantic View Map

Which semantic view is the natural-language / Cortex Analyst surface for each
Pentaho report. Semantic views do **not** build the reports themselves — the
`models/marts/reports/rpt_*` models plus Power BI do that. Each view is the
conversational surface for the reports at its grain, built on the same fact the
report reads.

The mapping below is derived from each `rpt_` model's upstream `ref()` and the
fact each semantic view is built on. See [`README.md`](README.md) for the
semantic-view design and [`models/marts/reports/README.md`](../models/marts/reports/README.md)
for report status.

## Mapping

| Pentaho report | `rpt_` model | Backing fact | Domain semantic view | Also in `UNIFIED`? |
|---|---|---|---|---|
| Daily Performance Report (New/MTD/YTD) | `rpt_daily_performance_report` | `FCT_DAILY_PERFORMANCE` | **`dpr`** | ✅ full |
| Memorial Museum Daily Tracker YTD | `rpt_memorial_museum_tracker_ytd` | `FCT_DAILY_PERFORMANCE` | **`dpr`** | ✅ full |
| Retail Performance Report | `rpt_retail_performance` | `FCT_RETAIL_DAILY` | **`retail`** | ✅ full |
| Retail Carts Analysis | `rpt_retail_carts_analysis` | `FCT_RETAIL_DAILY` | **`retail`** | ✅ full |
| Monthly Retail KPI | `rpt_monthly_retail_kpi` | `FCT_RETAIL_DAILY` | **`retail`** | ✅ full |
| Daily Scan Report | `rpt_daily_scan` | `FCT_DAILY_SCAN` | **`attendance`** | ✅ full |
| Attendance Report _(stub)_ | `rpt_attendance` | `FCT_DAILY_PERFORMANCE` + Sensource | **`attendance`** | ⚠️ partial — DPR attendance only, not the Sensource blend |
| Daily Attendance Report _(stub)_ | `rpt_daily_attendance` | `FCT_DAILY_PERFORMANCE` + hourly passes | **`attendance`** | ⚠️ partial — DPR attendance only, not hourly |
| Today's Sales | _(no `rpt_`; fact only)_ | `FCT_TODAY_SALES_HOURLY` | **`attendance`** | ❌ excluded (hourly grain) |
| Website Commerce Report _(stub)_ | `rpt_website_commerce` | `RPT_WEBSITE_COMMERCE` | **`fundraising_ecom`** | ❌ excluded (monthly grain) |
| Blue State WiFi Email Export _(stub)_ | `rpt_wifi_email_export` | `stg_wifi__audience` | **none — by design** | ❌ (PII export, not a chat surface) |

## Notes

- **Retail view spans two facts.** `retail` also covers `FCT_RETAIL_PERFORMANCE`
  (category grain) via its `retail_category` table for product-category
  drill-downs. That grain backs the category detail inside the retail reports
  rather than one specific Pentaho report.
- **`dpr` "Excel Data".** The `dpr` view also backs the DPR "Excel Data" export
  variant, which reads the same `FCT_DAILY_PERFORMANCE` grain.
- **Why three rows are not in `UNIFIED`.** `UNIFIED` spans only the four **live
  day-grain** facts. It deliberately leaves to the domain views: the
  Sensource-blended and hourly attendance components, the monthly Website
  Commerce surface, and the WiFi PII export. The DPR-sourced attendance measures
  (`total_museum_attendance`, `total_memorial_attendance`) _are_ in `UNIFIED`;
  only the Sensource/hourly components are not.
- **WiFi export has no semantic view on purpose.** `rpt_wifi_email_export` is a
  restricted PII extract (least-privilege grant only — see
  [`DATA_CLASSIFICATION.md`](../docs/architecture/DATA_CLASSIFICATION.md)), not a
  surface to expose to Cortex Analyst.

## Rule of thumb

The four **domain views map 1:1 to their report clusters**
(`dpr` → DPR reports, `retail` → retail reports, `attendance` → scan/attendance
reports, `fundraising_ecom` → website commerce). **`UNIFIED`** is the
cross-domain superset that fully covers every report at day grain and punts the
non-day-grain and PII surfaces back to the domain models.