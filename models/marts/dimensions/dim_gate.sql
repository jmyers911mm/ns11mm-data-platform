-- Marts dimension: dim_gate — gate / access-control-point dimension for scan attribution
-- ---------------------------------------------------------------------------
-- Domain: admissions / ticketing (attendance)
-- Grain: one row per acp_unique_id (access control point)
--
-- Combines ACP devices with their parent facility to provide a single gate
-- dimension for scan/usage attribution, and carries the resolved 911dw
-- key_facility so a scan fact can be sliced by attendance line without
-- re-deriving the map.
--
-- JOIN FIX (8.7.0): the ACP -> facility join was `acps.facility_id =
-- facility.facility_id`. The legacy path is
-- ACPs.FacilityID = Facility.IDNo, and the 7 -> 1006 / 12 -> 5000 map is then
-- read off Facility.FacilityID -- a different column from the join key
-- (t_fact_museum_passes_scanned). Joining the two FacilityID-named columns to
-- each other attributed gates to the wrong venue wherever IDNo <> FacilityID.
--
-- Source: stg_gateway__acps + stg_gateway__facility + seed_gateway_facility_map

{{ config(materialized='table', tags=['daily', 'critical']) }}

with acps as (
    select * from {{ ref('stg_gateway__acps') }}
),

facilities as (
    -- Dedup to one row per id_no: stg_gateway__facility is facility_id grain, so
    -- id_no (the ACP join key) is not guaranteed unique and could fan the gate out.
    select
        id_no,
        facility_id,
        facility_name,
        description,
        capacity
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
)

select
    a.acp_unique_id                     as gate_key,
    a.acp_id,
    trim(a.acp_name)                    as acp_name,
    a.node_no                           as node_id,
    a.facility_id                       as acp_facility_id_no,   -- ACPs.FacilityID (= Facility.IDNo)
    f.facility_id                       as gateway_facility_id,  -- Facility.FacilityID (the mapped column)
    coalesce(m.key_facility, 0)         as key_facility,         -- legacy else '0'
    coalesce(m.facility_label, 'Unmapped Gate') as facility_label,
    coalesce(m.is_excluded, false)      as is_excluded_from_scans,
    trim(f.facility_name)               as facility_name,
    trim(f.description)                 as facility_desc,
    a.kind                              as acp_kind,
    a.acp_group_id,
    f.capacity,
    true                                as is_active,
    current_timestamp()                 as _loaded_at
from acps a
left join facilities   f on a.facility_id = f.id_no
left join facility_map m on f.facility_id = m.gateway_facility_id
