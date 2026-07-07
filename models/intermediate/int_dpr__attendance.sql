-- Silver DPR: scan-based museum and memorial attendance
-- ---------------------------------------------------------------------------
-- Domain: attendance
-- Grain:  one row per key_date
--
-- Recreates the DPR memorial-attendance line item (and a scanned-museum
-- companion for reconciliation) from the Gateway usage/scan feed now exposed
-- by int_ticket_scans. Attendance = valid scans (passes) at the facility,
-- which is the Gateway component of the legacy t_reporting_mem_attendance /
-- t_reporting_mus_attendance line items (fact_visitors.passes_scanned).
--
-- Legacy lineage: t_fact_museum_passes_scanned (usage + acps + facility),
-- t_reporting_mem_attendance, t_reporting_mus_attendance.
--
-- SCOPE NOTE (ADR-005 gate):
--   * Museum vs. memorial is classified from stg_gateway__facility.facility_name
--     (name pattern) rather than the legacy numeric key_facility map
--     (museum 1006/3000, memorial 2000), because the RAW seed load carries
--     facility NAMES, not the 911dw key_facility surrogate keys. Confirm the
--     name-to-area mapping with Kenny Yeung / Chris Wogas before go-live; if a
--     facility should map elsewhere, adjust the CASE below (or promote it to a
--     seed) rather than editing downstream models.
--   * mem_attendance here is the SCAN component only. The legacy museum
--     attendance additionally blends Sensource turnstile counts, which are not
--     yet staged; mus_attendance_scanned is therefore provided for QA against
--     the existing ga-ticket proxy in int_dpr__admissions, and is intentionally
--     NOT wired into fct_daily_performance to avoid redefining a live measure.

{{ config(materialized='view') }}

with scans as (
    select
        scan_date                                                          as key_date,
        facility_id,
        visitor_count
    from {{ ref('int_ticket_scans') }}
    where is_valid_scan
      and scan_date is not null
),

facility as (
    select
        facility_id,
        facility_name
    from {{ ref('stg_gateway__facility') }}
),

classified as (
    select
        s.key_date,
        case
            when upper(coalesce(f.facility_name, '')) like '%MEMORIAL%'
              or upper(coalesce(f.facility_name, '')) like '%PLAZA%'   then 'memorial'
            when upper(coalesce(f.facility_name, '')) like '%MUSEUM%'  then 'museum'
            else 'other'
        end                                                                as area,
        s.visitor_count
    from scans s
    left join facility f on s.facility_id = f.facility_id
)

select
    key_date,
    sum(case when area = 'memorial' then visitor_count else 0 end)         as mem_attendance,
    sum(case when area = 'museum'   then visitor_count else 0 end)         as mus_attendance_scanned
from classified
group by key_date
