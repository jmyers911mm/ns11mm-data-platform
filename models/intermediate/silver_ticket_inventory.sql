/*
  silver_ticket_inventory
  Sources: stg_gateway__ticket_types + stg_gateway__transactions
  STATUS: Awaiting RAW data + capacity config source confirmation.
  NOTE: In POC this joined stg_ticket_capacity (a seed) with stg_pos_tickets.
  In production, capacity config may come from Gateway directly or remain
  a manually maintained seed. Confirm with Operations (James Okafor).
  Logic migrated from POC.
*/

{{
    config(
        materialized='incremental',
        unique_key='inventory_key',
        incremental_strategy='merge',
        cluster_by=['entry_date', 'ticket_type_id']
    )
}}

with capacity as (
    -- TODO: Replace with actual capacity source once confirmed
    -- Options: (a) Gateway SQL table, (b) manually maintained seed
    select
        null::date          as entry_date,
        null::time          as entry_window_start,
        null::time          as entry_window_end,
        null::varchar       as ticket_type,
        null::integer       as capacity,
        false               as is_override
    where 1 = 0
),

reservations as (
    select
        transaction_date    as entry_date,
        null::time          as entry_window_start,
        ticket_type_id      as ticket_type,
        sum(quantity)       as tickets_reserved
    from {{ ref('stg_gateway__transactions') }}
    where session_id is not null
    group by 1, 2, 3
)

select
    c.entry_date || '-' || coalesce(c.entry_window_start::varchar, 'ALL') || '-' || c.ticket_type as inventory_key,
    c.entry_date,
    c.entry_window_start,
    c.entry_window_end,
    c.ticket_type                                           as ticket_type_id,
    c.capacity                                              as ticket_capacity,
    coalesce(r.tickets_reserved, 0)                        as tickets_reserved,
    c.capacity - coalesce(r.tickets_reserved, 0)           as tickets_available,
    round(coalesce(r.tickets_reserved, 0)::float / nullif(c.capacity, 0) * 100, 2) as utilization_pct,
    case
        when coalesce(r.tickets_reserved, 0)::float / nullif(c.capacity, 0) >= 0.95 then 'Sold Out'
        when coalesce(r.tickets_reserved, 0)::float / nullif(c.capacity, 0) >= 0.80 then 'High Demand'
        when coalesce(r.tickets_reserved, 0)::float / nullif(c.capacity, 0) >= 0.50 then 'Moderate'
        when coalesce(r.tickets_reserved, 0)::float / nullif(c.capacity, 0) >= 0.20 then 'Low'
        else 'Very Low'
    end                                                     as demand_level,
    c.is_override,
    current_timestamp()                                     as _loaded_at
from capacity c
left join reservations r
    on  c.entry_date = r.entry_date
    and c.entry_window_start = r.entry_window_start
    and c.ticket_type = r.ticket_type

{% if is_incremental() %}
where c.entry_date >= (select max(entry_date) - 7 from {{ this }})
{% endif %}
