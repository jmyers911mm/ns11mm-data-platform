-- Marts report: thin SEMANTIC_VIEW() projection of the ATTENDANCE semantic view for Power BI (Daily Scan)
-- ---------------------------------------------------------------------------
-- Domain: attendance / scanning
-- Grain:  one row per report_date x segment_key
--
-- Thin wrapper over the MARTS.ATTENDANCE semantic view's FCT_DAILY_SCAN
-- metrics (Power BI cannot browse a SEMANTIC VIEW object, so the
-- SEMANTIC_VIEW() query is wrapped in a normal view). Additive measures only:
-- actual tickets sold, forecast (DSR budget), and passes scanned. Feeds the
-- Power BI Daily Scan report dataset.
-- NOTE: the report's shares (% used, % of market) and forecast variance % are
-- non-additive and recompute at the display grain from summed components.
-- Forecast (PASSES_BUDGET) is the real DSR forecast joined in fct_daily_scan
-- ("Forecast Tickets Sold" on the report).
--
-- ADR-004: all business logic in dbt / the semantic view, never Power BI.

{{ config(materialized='view', grants={'select': ['POWERBI_ROLE']}) }}

select * from semantic_view(
    {{ source('attendance_semantic', 'ATTENDANCE') }}

    dimensions
        dt.report_date                 as report_date,
        dt.day_of_week_name            as day_name,
        ds.segment_key                 as segment_key,
        ds.segment_name                as segment_name,
        ds.is_commemoration_day        as is_commemoration_day

    metrics
        ds.total_tickets_scanned       as tickets_sold,
        ds.total_passes_scanned        as passes_scanned,
        ds.total_passes_budget         as forecast_tickets_sold
)