-- Marts report: Attendance Report
-- Co-authored with CoCo
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
        mus_store_vesey,
        mem_attendance                             as sensource_mem_attendance,
        mus_attendance                             as sensource_mus_attendance
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