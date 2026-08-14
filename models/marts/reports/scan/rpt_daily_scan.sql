-- Marts report: Daily Scan Report
-- ---------------------------------------------------------------------------
-- Domain: attendance / scanning
-- Grain: one row per date_key x segment_key, plus a daily total context column
--
-- Presentation view for report.daily_scan_report_new. Adds the report's
-- market-mix percentages at query grain: each segment's share of total passes
-- scanned and tickets sold for the day, plus scanned-vs-sold utilization.
-- Percentages divide by the day total (window sum), never averaged. Budget
-- (the DSR forecast) is joined in fct_daily_scan from stg_budget__daily_scan;
-- variance is NULL only for dates/segments the forecast has not been loaded for.
--
-- SCOPE NOTE (ADR-005 gate, 8.7.0) — owner Chris Wogas: passes_scanned is the
-- NET legacy measure (code 0 adds, code 11 subtracts, all other usage codes
-- dropped, Gateway facility 13 excluded), so both the printed counts and every
-- share below change value. gross_passes_scanned / reversed_passes_scanned are
-- carried through for reconciliation against the pre-8.7.0 figures. Shares stay
-- ratio-of-sums at display grain — no stored quotient (ratio rule).
-- ADR-004: no logic in Power BI.

{{ config(materialized='view') }}

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
    gross_passes_scanned,
    reversed_passes_scanned,
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
