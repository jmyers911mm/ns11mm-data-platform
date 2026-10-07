# 7.10.0: Reports 2–4 Serving Stack (Today's Sales · Daily Scan · YTD Tracker)

- **Date:** 2026-07-31
- **Version:** 7.10.0

Lands the component stack the 2026-07-29 build notes specified but that never reached the
repo: only the thin wrappers and semantic-view additions existed. Each report now has the
full Retail-pattern stack (report_long, line-item seed + dim where applicable, narrative
chain, task setup script). 18 files added, 5 edited; all patterns mirror the existing DPR
and Retail stacks.

## Added

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

## Changed

- `rpt_memorial_museum_tracker_ytd` — header corrected (it claimed budget columns were
  joined; none were) and marked superseded for the Power BI build by the `rpt_tracker_*`
  stack (kept for existing consumers); now also carries `tickets_sold` +
  `tickets_sold_ytd` (the tracker's Museum panel requires it).
- `models/marts/reports/schema.yml` (11 new entries, severities per the rule),
  `models/marts/dimensions/schema.yml` (2 dim entries), `seeds/_seeds.yml` (2 seeds),
  `models/marts/reports/README.md` (inventory updated: 34 files / 29 build / 5 gated).

## Deploy order (per the build notes)

1. `dbt seed --select today_sales_line_items tracker_line_items`
2. `dbt build --select rpt_today_sales_report_long rpt_daily_scan_report_long rpt_tracker_powerbi+ dim_today_sales_line_item dim_tracker_line_item`
3. Run the three `scripts/setup_*_narrative.sql` (after `USE DATABASE <target>`); eyeball
   the first notes; `ALTER TASK ... RESUME`.
4. Build each PBIX; reconcile to a recent legacy PDF; route through change control.

## Sign-off gates (open, from the build notes — not blockers)

- Confirm the DSR forecast basis (tickets-sold vs scanned forecast).
- Confirm the tracker's earned-revenue and projection definitions vs the legacy PDF.
- Decide the Memorial-vs-Museum revenue-split business rule (ADR-005) — the two Stub
  rows light up when it lands.
- Memorial Cart 1/2/3 split needs `store_id` retained in `fct_today_sales_hourly`
  (small fact change, separate PR).

---
