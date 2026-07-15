-- Silver intermediate: ticket scan / usage events for gate admission counts
-- ---------------------------------------------------------------------------
-- Domain: admissions / ticketing (attendance)
-- Grain:  one row per usage_id (scan event), where use_time is not null
--
-- Reshapes stg_gateway__usage into an admission-scan line: scan_date (from
-- use_time), gate_id (acp_id), facility, visitor_count (quantity), a validity
-- flag, and entry method. Feeds the scans CTE in fct_daily_operations, which
-- sums visitor_count on valid scans for total_visitors and counts valid vs.
-- rejected scans and active gates.
-- NOTE: is_valid_scan is defined as status_code in (0, 1); that set is the rule
-- that decides which scans count as admissions, so confirm the valid-status
-- codes with the attendance metric owner (ADR-005) before this feeds anything
-- certified. is_override is passed through from the raw scan.
--
-- ADR-001: reads only from stg_ (RAW is upstream and immutable).
-- ADR-004: all business logic lives here, not in Power BI.

{{ config(materialized='view') }}

select
    usage_id                                        as scan_id,
    visual_id,                                      -- ticket link for market-segment join (Daily Scan)
    use_time::date                                  as scan_date,
    acp_id                                          as gate_id,
    facility_id,
    quantity                                        as visitor_count,
    status_code::varchar in ('0', '1')              as is_valid_scan,
    entry_method,
    is_override,
    _loaded_at                                      as _extracted_at
from {{ ref('stg_gateway__usage') }}
where use_time is not null