/*
  dim_gate
  Source: silver_ticket_scans
  STATUS: Awaiting RAW data.
  Gate names/locations are hardcoded mappings — update once Gateway schema confirmed.
*/

{{ config(enabled=false,materialized='table') }}

with gates as (
    select distinct gate_id
    from {{ ref('silver_ticket_scans') }}
    where gate_id is not null
)

select
    gate_id,
    case gate_id
        when 'GATE-MAIN'   then 'Main Entrance'
        when 'GATE-NORTH'  then 'North Wing Entrance'
        when 'GATE-SOUTH'  then 'South Wing Entrance'
        when 'GATE-MEMBER' then 'Members Only Entrance'
        else gate_id
    end as gate_name,
    case gate_id
        when 'GATE-MAIN'   then 'Lobby'
        when 'GATE-NORTH'  then 'North Wing'
        when 'GATE-SOUTH'  then 'South Wing'
        when 'GATE-MEMBER' then 'East Wing'
        else 'Unknown'
    end as location,
    case when gate_id = 'GATE-MEMBER' then true else false end as is_members_only,
    case when gate_id = 'GATE-MAIN'   then true else false end as is_primary_entrance,
    current_timestamp() as _loaded_at
from gates
