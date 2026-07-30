-- Marts dimension: dim_gate — gate / access-control-point dimension for scan attribution
-- ---------------------------------------------------------------------------
-- Domain: admissions / ticketing (attendance)
-- Grain: one row per acp_unique_id (access control point)
--
-- Combines ACP devices with their parent facility to provide a single gate
-- dimension for scan/usage attribution.
--
-- Source: stg_gateway__acps + stg_gateway__facility

{{ config(materialized='table', tags=['daily', 'critical']) }}

with acps as (
    select * from {{ ref('stg_gateway__acps') }}
),

facilities as (
    select * from {{ ref('stg_gateway__facility') }}
)

select
    a.acp_unique_id                     as gate_key,
    a.acp_id,
    trim(a.acp_name)                    as acp_name,
    a.node_no                           as node_id,
    a.facility_id,
    trim(f.facility_name)               as facility_name,
    trim(f.description)                 as facility_desc,
    a.kind                              as acp_kind,
    a.acp_group_id,
    f.capacity,
    true                                as is_active,
    current_timestamp()                 as _loaded_at
from acps a
left join facilities f on a.facility_id = f.facility_id
