-- Silver intermediate: gate scan (usage) events with the legacy scan-validity rule
-- ---------------------------------------------------------------------------
-- Domain: admissions / ticketing (attendance)
-- Grain:  one row per usage_id (scan event), where use_time is not null
--
-- Reshapes stg_gateway__usage into an admission-scan line: scan_date (from
-- use_time), gate_id (acp_id), the RESOLVED facility (via the ACP path), a
-- signed net_visitor_count, the validity flags, and entry method. Feeds
-- int_gateway__scan_lines (-> fct_daily_scan), int_dpr__attendance (-> the DPR
-- and Attendance Report attendance lines) and fct_daily_operations.
--
-- Legacy lineage: t_fact_museum_passes_scanned (dbo.Usage + ACPs + Facility,
-- writing 911dw.fact_visitors.passes_scanned).
--
-- SCOPE NOTE (ADR-005 gate) — owner Chris Wogas. This model changes what a
-- "valid scan" counts, and therefore changes passes_scanned and every
-- attendance figure and per-capita ratio built on it. Two definitional changes:
--
--   1. VALIDITY. Legacy counts a scan only when Usage.Status = 0, and splits on
--      Usage.Code: code 0 adds +SUM(Qty), code 11 adds -SUM(Qty) (the UNION's
--      second leg), and every other code is dropped. The previous version of
--      this model used `status_code in ('0','1')` with no code predicate, which
--      (a) admitted status 1, (b) never subtracted the code-11 reversals, and
--      (c) counted every other usage code as an admission. Both directions of
--      error are now removed.
--   2. FACILITY. Legacy resolves the facility through the access point --
--      Usage.ACP -> ACPs.AcpId -> ACPs.FacilityID -> Facility.IDNo -- and then
--      reads Facility.FacilityID (a DIFFERENT column from the join key) through
--      the 7 -> 1006 / 12 -> 5000 map, dropping Facility.FacilityID = 13. The
--      previous version used stg_gateway__usage.facility_id directly, which
--      bypasses the ACP hop entirely and is not the same column the legacy map
--      is keyed on. The map and the exclusion now live in
--      seed_gateway_facility_map.
--
-- NOTE (source columns): stg_gateway__usage already exposes both `code` and
-- `status_code`, so no staging change was required for this release
-- (ADR-001 keeps stg_ rename/recast only).
-- NOTE (grain guards): stg_gateway__acps is acp_unique_id grain and
-- stg_gateway__facility is facility_id grain, so acp_id and id_no are not
-- guaranteed unique. Both lookups are deduplicated below to one row per join
-- key so the scan grain cannot fan out.
--
-- ADR-001: reads only from stg_ (RAW is upstream and immutable).
-- ADR-004: all business logic lives here, not in Power BI.
-- ADR-005: validity and facility definitions are gated -- see DECISION_MEMO.

{{ config(materialized='view') }}

with usage as (
    select * from {{ ref('stg_gateway__usage') }}
),

acps as (
    -- Usage.ACP -> ACPs.AcpId. Dedup to one row per acp_id (latest device
    -- record wins) so a re-registered access point cannot duplicate a scan.
    select
        acp_id,
        facility_id                                     as acp_facility_id_no
    from {{ ref('stg_gateway__acps') }}
    qualify row_number() over (
        partition by acp_id
        order by last_updated_at desc nulls last, acp_unique_id desc
    ) = 1
),

facility as (
    -- ACPs.FacilityID -> Facility.IDNo. facility_id (Facility.FacilityID) is the
    -- column the legacy CASE maps; id_no is only the join key.
    select
        id_no,
        facility_id                                     as gateway_facility_id
    from {{ ref('stg_gateway__facility') }}
    where id_no is not null
    qualify row_number() over (
        partition by id_no
        order by last_updated_at desc nulls last, facility_id desc
    ) = 1
),

facility_map as (
    select
        gateway_facility_id,
        key_facility,
        facility_label,
        is_excluded
    from {{ ref('seed_gateway_facility_map') }}
),

resolved as (
    select
        u.usage_id,
        u.visual_id,
        u.use_time,
        u.acp_id,
        u.facility_id                                   as usage_facility_id,
        f.gateway_facility_id,
        -- Legacy `else '0'`: an ACP whose facility is neither 7 nor 12 lands in
        -- the 0 bucket rather than being dropped, so it stays countable in the
        -- unmapped monitor without touching either attendance line.
        coalesce(m.key_facility, 0)                     as key_facility,
        coalesce(m.facility_label, 'Unmapped Gate')     as facility_label,
        coalesce(m.is_excluded, false)                  as is_facility_excluded,
        u.status_code,
        u.code,
        u.quantity,
        u.entry_method,
        u.is_override,
        u._loaded_at
    from usage u
    left join acps         a on u.acp_id             = a.acp_id
    left join facility     f on a.acp_facility_id_no = f.id_no
    left join facility_map m on f.gateway_facility_id = m.gateway_facility_id
    where u.use_time is not null
),

classified as (
    select
        *,
        -- Legacy validity: Status = 0 AND Code = 0 adds, Status = 0 AND
        -- Code = 11 subtracts, everything else contributes nothing. Facility 13
        -- is excluded from BOTH legs.
        case
            when is_facility_excluded                                       then 0
            when status_code::varchar = '0' and code::varchar = '0'         then 1
            when status_code::varchar = '0' and code::varchar = '11'        then -1
            else 0
        end                                             as scan_sign
    from resolved
)

select
    usage_id                                            as scan_id,
    visual_id,                                          -- ticket link for market-segment join (Daily Scan)
    use_time::date                                      as scan_date,
    acp_id                                              as gate_id,
    usage_facility_id                                   as facility_id,   -- source-native, retained for QA
    gateway_facility_id,
    key_facility,
    facility_label,
    is_facility_excluded,
    status_code,
    code                                                as usage_code,
    scan_sign,
    quantity                                            as visitor_count,        -- raw source qty (unsigned)
    quantity * scan_sign                                as net_visitor_count,    -- legacy passes-scanned contribution
    scan_sign = 1                                       as is_valid_scan,        -- admitted entry (status 0, code 0)
    scan_sign = -1                                      as is_reversing_scan,    -- code-11 negation leg
    scan_sign <> 0                                      as is_counted_scan,      -- either leg (drives passes scanned)
    entry_method,
    is_override,
    _loaded_at                                          as _extracted_at
from classified
