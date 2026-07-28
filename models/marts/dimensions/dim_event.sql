-- Marts dimension: dim_event — timed-entry events, tours, programs, and shows
-- Co-authored with CoCo
-- ---------------------------------------------------------------------------
-- Domain: admissions / ticketing (timed entry)
-- Grain: one row per event_id
--
-- Timed-entry events, tours, programs, and shows from Gateway's resource
-- management system.
--
-- Source: stg_gateway__rmevents

{{ config(materialized='table', tags=['daily', 'critical']) }}

with events as (
    select * from {{ ref('stg_gateway__rmevents') }}
)

select
    event_id                            as event_key,
    event_id,
    trim(event_name)                    as event_name,
    event_type_id,
    event_program_id,
    start_at                            as start_datetime,
    end_at                              as end_datetime,
    on_sale_at                          as on_sale_datetime,
    off_sale_at                         as off_sale_datetime,
    resource_id,
    node_number,
    case when is_active = 1 then true else false end    as is_active,
    case when is_private_event = 1 then true else false end as is_private,
    case when has_roster = 1 then true else false end   as has_roster,
    case when has_waitlist = 1 then true else false end  as has_waitlist,
    current_timestamp()                 as _loaded_at
from events
