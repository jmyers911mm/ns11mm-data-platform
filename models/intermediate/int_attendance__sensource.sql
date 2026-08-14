-- Silver intermediate: Sensource attendance by reporting area
-- ---------------------------------------------------------------------------
-- Domain: attendance
-- Grain:  one row per date_key
--
-- Pivots the crosswalked attendance counts into the four named areas the
-- Attendance Report prints, plus the memorial-only difference. The three
-- fact_visitors areas (Atrium, Museum Store, Museum Store at Vesey) come from
-- int_retail__visitors rather than by re-resolving the crosswalk, so the sensor
-- -> reporting-facility pivot is authored exactly once; the Memorial Plaza line
-- comes from stg_memorial__attendance, which is a different legacy table. Areas
-- are selected by the crosswalk's own area_name, never by raw facility numbers.
-- Feeds rpt_attendance, which supplies rpt_attendance_report_long's
-- MEMORIAL_ONLY / MUSEUM_STORE / MUSEUM_STORE_VESEY lines.
--
-- Legacy lineage: t_fact_attendance_all_locations (911dw.fact_attendance_all_
-- locations). Its four UNION legs read 911dw.memorial_attendance at 2000
-- (:14-17), 911dw.fact_visitors passes_scanned at 1006 (:21-24, legacy IN list
-- 1006+3000), num_entry at 1007 (:28-32) and num_exit at 1001 (:36-40).
-- NOTE (memorial source, 8.4.0): the memorial line previously read the 2000 rows
-- of the visitors feed, which cannot exist -- neither writer of
-- 911dw.fact_visitors emits 2000 (t_fact_museum_passes_scanned emits only
-- 1006, 5000 and 0; the Sensource API leg covers ParentFacility 1000-1009).
-- Legacy reads it from the separate 911dw.memorial_attendance table and so does
-- this model, through the seed's memorial_feed rows.
-- SCOPE NOTE: memorial_only is the memorial-minus-museum pair, exactly as
-- t_fact_attendance_all_locations.sql:10 computes it. The Attendance Report's
-- printed Memorial and Museum lines still come from the DPR fact (scan
-- component), so printed Memorial - printed Museum will not tie to printed
-- Memorial Only until the two attendance definitions are reconciled. That
-- reconciliation is an ADR-005 metric decision (owner: Chris Wogas).
--
-- ADR-004: all business logic in dbt, never Power BI.

{{ config(materialized='view') }}

with visitors as (
    select * from {{ ref('int_retail__visitors') }}
),

memorial as (
    select * from {{ ref('stg_memorial__attendance') }}
),

facility_map as (
    select * from {{ ref('seed_sensource_facility_map') }}
),

-- One label per reporting facility, for the legs int_retail__visitors publishes.
sensor_areas as (
    select distinct
        reporting_facility,
        area_name
    from facility_map
    where source_system in ('sensource', 'gateway_scan')
      and is_reporting
),

-- The memorial leg's own crosswalk row: which key_facility of
-- 911dw.memorial_attendance is counted, and under which area label. Kept in the
-- seed so the 2000 vs (1000, 2000) legacy disagreement is a data edit.
memorial_map as (
    select
        sensource_facility,
        area_name
    from facility_map
    where source_system = 'memorial_feed'
      and is_reporting
),

sensor_labelled as (
    select
        v.date_key,
        a.area_name,
        v.visitor_count
    from visitors v
    inner join sensor_areas a
        on v.key_facility = a.reporting_facility
),

memorial_labelled as (
    select
        m.business_date                                 as date_key,
        mm.area_name,
        m.passes_scanned                                as visitor_count
    from memorial m
    inner join memorial_map mm
        on m.key_facility = mm.sensource_facility
    where m.business_date is not null
),

labelled as (
    select date_key, area_name, visitor_count from sensor_labelled
    union all
    select date_key, area_name, visitor_count from memorial_labelled
),

pivoted as (
    select
        date_key,
        sum(case when area_name = 'Memorial Plaza'           then visitor_count else 0 end) as memorial_attendance,
        sum(case when area_name = 'Atrium'                   then visitor_count else 0 end) as museum_attendance,
        sum(case when area_name = 'Museum Store'             then visitor_count else 0 end) as museum_store,
        sum(case when area_name = 'Museum Store (at Vesey)'  then visitor_count else 0 end) as museum_store_vesey
    from labelled
    group by 1
)

select
    date_key,
    memorial_attendance,
    museum_attendance,
    -- t_fact_attendance_all_locations.sql:10
    --   sum(memorial_attendance - museum_attendance) as 'Memorial Only'
    memorial_attendance - museum_attendance             as memorial_only,
    museum_store,
    museum_store_vesey
from pivoted
