-- =====================================================================
-- DAILY_SCAN_POWERBI  -  Power BI consumption view over the ATTENDANCE
-- semantic view (FCT_DAILY_SCAN). Twin of rpt_dpr_powerbi / rpt_retail_powerbi.
-- ---------------------------------------------------------------------
-- One row per (REPORT_DATE, SEGMENT_KEY). Additive measures only: actual
-- tickets sold, forecast (DSR budget), and passes scanned. The report's
-- shares (% used, % of market) and forecast variance % are non-additive and
-- recompute at the display grain from summed components -- see
-- rpt_daily_scan_report_long (SQL) / the existing rpt_daily_scan, per ADR-004.
--
-- Forecast (PASSES_BUDGET) is the real DSR forecast joined in fct_daily_scan;
-- it is the "Forecast Tickets Sold" column on the report.
-- =====================================================================

-- models/marts/reports/rpt_daily_scan_powerbi.sql
{{ config(materialized='view', grants={'select': ['POWERBI_ROLE']}) }}

select * from semantic_view(
    {{ source('attendance_semantic', 'ATTENDANCE') }}

    dimensions
        dim_date.report_date                 as report_date,
        dim_date.day_of_week_name            as day_name,
        fct_daily_scan.segment_key           as segment_key,
        fct_daily_scan.segment_name          as segment_name,
        fct_daily_scan.is_commemoration_day  as is_commemoration_day

    metrics
        fct_daily_scan.total_tickets_scanned as tickets_sold,
        fct_daily_scan.total_passes_scanned  as passes_scanned,
        fct_daily_scan.total_passes_budget   as forecast_tickets_sold
)