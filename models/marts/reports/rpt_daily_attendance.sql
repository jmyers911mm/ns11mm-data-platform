-- Marts report: Daily Attendance Report
-- ---------------------------------------------------------------------------
-- Domain: attendance
-- Grain: one row per date_key
--
-- Presentation view for report.daily_attendance_report. Legacy reads
-- SUM(passes) from 911dw.fact_passes_by_hour. Built here from the hourly-passes
-- stub (empty until the hourly passes feed lands); falls back to the scan-based
-- museum attendance from fct_daily_performance so the report is non-empty today.
-- ADR-004: no logic in Power BI.

{{ config(materialized='view') }}

with passes as (
    select
        cast(business_date as date)     as date_key,
        sum(passes)                     as passes
    from {{ ref('stg_gateway__passes_by_hour') }}
    group by 1
),

dpr as (
    select date_key, date_value, mus_attendance
    from {{ ref('fct_daily_performance') }}
)

select
    d.date_key,
    d.date_value,
    coalesce(p.passes, d.mus_attendance)    as museum_attendance,   -- hourly passes stub, scan fallback
    p.passes                                as passes_by_hour_total  -- null until feed lands
from dpr d
left join passes p on d.date_value = p.date_key