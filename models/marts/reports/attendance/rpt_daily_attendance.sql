-- Marts report: Daily Attendance Report
-- ---------------------------------------------------------------------------
-- Domain: attendance
-- Grain: one row per date_key
--
-- Presentation view for report.daily_attendance_report. Legacy reads
-- SUM(passes) from 911dw.fact_passes_by_hour. Built here from the hourly-passes
-- stub (empty until the hourly passes feed lands); falls back to the scan-based
-- museum attendance from fct_daily_performance so the report is non-empty today.
--
-- SCOPE NOTE (ADR-005 gate, 8.7.0) — owner Chris Wogas: the fallback value
-- changed. fct_daily_performance.mus_attendance is now the legacy measure
-- (scanned passes at key_facility 1006/3000, code-0 minus code-11, closed-day
-- zeroing applied) rather than the GA ticket quantity, so this report's museum
-- attendance moves on every date where the hourly-passes feed is still empty.
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
