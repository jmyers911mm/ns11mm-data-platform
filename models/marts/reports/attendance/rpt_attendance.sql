-- Marts report: Attendance Report
-- ---------------------------------------------------------------------------
-- Domain: attendance
-- Grain: one row per date_key
--
-- Presentation view for report.attendance_report. Combines DPR attendance
-- (mem/mus) with the three Sensource-derived area counts: the memorial-only
-- plaza difference and the two store door counts. 8.4.0 repoints the Sensource
-- half from stg_sensource__attendance (a pre-pivoted landing table that has no
-- facility crosswalk and no legacy provenance) to int_attendance__sensource,
-- which derives all three from the crosswalked sensor feed the legacy report
-- actually used. That also removes the staging read this model had been
-- carrying in the marts layer.
--
-- Legacy lineage: t_fact_attendance_all_locations ->
-- 911dw.fact_attendance_all_locations.
-- SCOPE NOTE: the printed Memorial and Museum lines remain the DPR scan
-- measures; Memorial Only is the Sensource pair, per legacy. The two
-- definitions do not tie, so the printed rows will not subtract cleanly until
-- ADR-005 reconciles them (owner: Chris Wogas).
-- ADR-004: no logic in Power BI.

{{ config(materialized='view') }}

with dpr as (
    select date_key, date_value, is_commemoration_day, mem_attendance, mus_attendance
    from {{ ref('fct_daily_performance') }}
),

sensource as (
    select
        date_key,
        memorial_only,
        museum_store,
        museum_store_vesey
    from {{ ref('int_attendance__sensource') }}
)

select
    d.date_key,
    d.date_value,
    d.is_commemoration_day,
    d.mem_attendance                                   as memorial_attendance,
    d.mus_attendance                                   as museum_attendance,
    coalesce(s.memorial_only, 0)                       as memorial_only,
    coalesce(s.museum_store, 0)                        as museum_store,
    coalesce(s.museum_store_vesey, 0)                  as museum_store_vesey
from dpr d
left join sensource s on d.date_value = s.date_key
