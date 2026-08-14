-- Bronze staging: memorial plaza attendance (scanned passes)
-- ---------------------------------------------------------------------------
-- Domain: attendance
-- Grain:  one row per key_date x key_facility, as landed
--
-- Conforms seed_memorial_attendance, the landing of 911dw.memorial_attendance.
-- This is a SEPARATE legacy table from 911dw.fact_visitors and is the only
-- source of the Memorial Attendance line: neither writer of fact_visitors can
-- emit key_facility 2000 (t_fact_museum_passes_scanned emits only 1006, 5000
-- and 0; the Sensource API leg covers ParentFacility 1000-1009). Feeds
-- int_attendance__sensource and, from 8.7.0, int_dpr__attendance.
--
-- Legacy lineage: 911dw.memorial_attendance, read by
-- t_fact_attendance_all_locations.sql:14-19, t_fact_attendance_all_facilities.
-- sql:10-15 and :42-47, and t_reporting_mem_attendance.sql:8-12. Every reader
-- filters key_facility and sums passes_scanned; key_date is YYYYMMDD.
-- NOTE (column set): the landed table may also carry an `acp` column, mirroring
-- fact_visitors. It is deliberately NOT projected — no legacy reader references
-- it, every reader aggregates over it, and projecting a column that may be
-- absent from the landing would make this model unbuildable. Its presence in
-- RAW is tolerated and simply sub-divides the landed grain.
-- NOTE (facility set): the legacy estate disagrees on the memorial facility
-- filter -- `in (2000)` in the two attendance objects, `in (1000,2000)` in
-- t_reporting_mem_attendance. Staging applies NO filter (ADR-001); the choice
-- is made downstream from a seed, where it is reviewable.
--
-- ADR-001: RAW is immutable, staging is rename/recast only.

{{ config(materialized='view') }}

with source as (
    select * from {{ ref('seed_memorial_attendance') }}
),

staged as (
    select
        try_to_date(key_date::varchar, 'YYYYMMDD')  as business_date,
        key_facility::integer                       as key_facility,
        passes_scanned::integer                     as passes_scanned,
        current_timestamp()                         as _loaded_at
    from source
)

select
    business_date,
    key_facility,
    passes_scanned,
    _loaded_at
from staged
