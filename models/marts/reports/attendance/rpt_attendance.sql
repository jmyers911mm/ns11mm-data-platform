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
-- SCOPE NOTE (ADR-005 gate, 8.7.0) — owner Chris Wogas:
--  * museum_attendance now carries the legacy definition (net scanned passes at
--    key_facility 1006/3000 with the closed-day zeroing), so its values change.
--  * memorial_attendance now carries the legacy definition too:
--    SUM(passes_scanned) from 911dw.memorial_attendance (stg_memorial__
--    attendance, staged in 8.4.0) at the seeded memorial key_facility, in place
--    of the '%MEMORIAL%' facility-name pattern-match artefact it published
--    before. Values change; the layout seed returns MEM_ATTENDANCE to
--    'Available'. It is still NOT coalesced to zero -- NULL means the feed has
--    no row for that day.
--  * The reconciliation note above now BITES rather than being theoretical.
--    memorial_attendance and memorial_only are both real numbers drawn from the
--    same 911dw.memorial_attendance table, but museum_attendance here is the
--    zeroed DPR scan measure while the museum term inside memorial_only is the
--    un-zeroed Atrium count from int_attendance__sensource. Printed Memorial -
--    printed Museum will therefore differ from printed Memorial Only on every
--    closed day, by exactly the zeroed amount. Legacy has the same seam; it is
--    ADR-005's to close.
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
    d.mem_attendance                                   as memorial_attendance,  -- 911dw.memorial_attendance; NULL = no feed row that day
    d.mus_attendance                                   as museum_attendance,
    coalesce(s.memorial_only, 0)                       as memorial_only,
    coalesce(s.museum_store, 0)                        as museum_store,
    coalesce(s.museum_store_vesey, 0)                  as museum_store_vesey
from dpr d
left join sensource s on d.date_value = s.date_key
