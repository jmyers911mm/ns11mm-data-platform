{{ config(materialized='view') }}

-- Marts report: Daily Scan Report
-- ---------------------------------------------------------------------------
-- Domain: attendance / scanning
-- Grain:  one row per date_key x segment_key, plus a daily total context column
--
-- Presentation view for report.daily_scan_report_new. Adds the report's
-- market-mix percentages at query grain: each segment's share of total passes
-- scanned and tickets sold for the day, plus scanned-vs-sold utilization.
-- Percentages divide by the day total (window sum), never averaged. Budget
-- variance is present but NULL until the DSR forecast seed is populated.
-- ADR-004: no logic in Power BI.

with fct as (
    select * from {{ ref('fct_daily_scan') }}
),

with_totals as (
    select
        *,
        sum(passes_scanned) over (partition by date_key) as day_total_scanned,
        sum(tickets_sold)   over (partition by date_key) as day_total_sold
    from fct
)

select
    date_key,
    date_value,
    segment_key,
    segment_name,
    is_commemoration_day,

    passes_scanned,
    tickets_sold,
    passes_budget,
    day_total_scanned,
    day_total_sold,

    -- Market-mix shares (of the day) and utilization, at query grain
    passes_scanned / nullif(day_total_scanned, 0)   as pct_of_scanned,
    tickets_sold   / nullif(day_total_sold, 0)       as pct_of_sold,
    passes_scanned / nullif(tickets_sold, 0)         as scan_utilization,
    passes_scanned - coalesce(passes_budget, 0)      as passes_variance

from with_totals