-- Marts report: Attendance Report
-- ---------------------------------------------------------------------------
-- Domain: attendance
-- Grain: one row per date_key
--
-- Presentation view for report.attendance_report. Combines DPR attendance
-- (mem/mus) with the Sensource "memorial_only" plaza count and the retail
-- store visitor counts. mem_attendance / mus_attendance come from
-- fct_daily_performance today; memorial_only + mus_store visitor counts come
-- from the Sensource stub (empty until sensordata lands). Store counts fall
-- back to retail transactions as an interim proxy.
--
-- 8.1.0 DEAD-CODE REMOVAL: the sensource CTE also selected the Sensource feed's
-- own mem_attendance / mus_attendance as sensource_mem_attendance /
-- sensource_mus_attendance. Neither was ever projected in the final select
-- (recorded in the 7.13.1 CHANGELOG caveats). They are removed rather than
-- surfaced: this report's memorial_attendance / museum_attendance are the
-- governed fct_daily_performance measures, and publishing a second,
-- differently-sourced attendance pair beside them is exactly the ambiguity the
-- Sensource blend decision (ADR-005, owner: Chris Wogas) has to settle first.
-- ADR-004: no logic in Power BI.

{{ config(materialized='view') }}

with dpr as (
    select date_key, date_value, is_commemoration_day, mem_attendance, mus_attendance
    from {{ ref('fct_daily_performance') }}
),

sensource as (
    -- Real Sensource feed is pre-aggregated by named area per day (no facility
    -- mapping): mem/mus attendance + memorial-only, store, store-Vesey counts.
    select
        business_date                              as date_key,
        memorial_only,
        mus_store,
        mus_store_vesey
    from {{ ref('stg_sensource__attendance') }}
)

select
    d.date_key,
    d.date_value,
    d.is_commemoration_day,
    d.mem_attendance                                   as memorial_attendance,
    d.mus_attendance                                   as museum_attendance,
    coalesce(s.memorial_only, 0)                       as memorial_only,
    coalesce(s.mus_store, 0)                            as museum_store,
    coalesce(s.mus_store_vesey, 0)                      as museum_store_vesey
from dpr d
left join sensource s on d.date_value = s.date_key