-- Silver intermediate: derived ticket inventory (reservations vs. capacity)
-- ---------------------------------------------------------------------------
-- Domain: admissions / ticketing (capacity)
-- Grain:  one row per entry_date + ticket_type_id (plu)
--
-- Rolls the demand features up to a daily per-type reservation count, then derives
-- a capacity figure and the availability measures on top of it: tickets_available,
-- utilization_pct, and a demand_level band (Sold Out / High Demand / Moderate /
-- Low). is_override is a hardcoded false placeholder for a future manual override.
-- NOTE: Gateway exposes no explicit capacity table, so capacity here is a PROXY,
-- the rolling 90-day max of daily reserved per type. Adequate for the ML demand
-- use case; it is not an authoritative sellable-capacity number. This proxy
-- propagates into fct_ticket_availability and both ml_ tables, so replace it once
-- a real capacity source lands. Feeds fct_ticket_availability.
--
-- ADR-001: reads only from stg_/int_ (RAW is upstream and immutable).
-- ADR-004: all business logic lives here, not in Power BI.

{{ config(materialized='view') }}

{#
  Since the Gateway data does not include an explicit capacity table, we derive
  capacity as the rolling 90-day max daily ticket count per ticket type (a proxy
  for "sold out" days). This is adequate for the ML demand forecasting use case.
#}

with daily_counts as (
    select
        entry_date,
        plu                                             as ticket_type_id,
        ticket_type_name                                as ticket_type,
        sum(quantity)                                   as tickets_reserved,
        count(distinct ticket_id)                       as ticket_count
    from {{ ref('int_gateway__ticket_demand_features') }}
    group by entry_date, plu, ticket_type_name
),

capacity_estimate as (
    select
        ticket_type_id,
        entry_date,
        -- Rolling 90-day max as capacity proxy
        max(tickets_reserved) over (
            partition by ticket_type_id
            order by entry_date
            rows between 90 preceding and current row
        )                                               as ticket_capacity
    from daily_counts
),

inventory as (
    select
        md5(dc.entry_date::varchar || '|' || dc.ticket_type_id)
                                                        as inventory_key,
        dc.entry_date,
        dc.entry_date                                   as entry_window_start,
        dc.entry_date                                   as entry_window_end,
        dc.ticket_type_id,
        dc.ticket_type,
        ce.ticket_capacity,
        dc.tickets_reserved,
        greatest(ce.ticket_capacity - dc.tickets_reserved, 0) as tickets_available,
        round(dc.tickets_reserved::float / nullif(ce.ticket_capacity, 0) * 100, 2) as utilization_pct,
        case
            when dc.tickets_reserved >= ce.ticket_capacity then 'Sold Out'
            when dc.tickets_reserved >= ce.ticket_capacity * 0.85 then 'High Demand'
            when dc.tickets_reserved >= ce.ticket_capacity * 0.5 then 'Moderate'
            else 'Low'
        end                                             as demand_level,
        false                                           as is_override
    from daily_counts dc
    inner join capacity_estimate ce
        on dc.ticket_type_id = ce.ticket_type_id
        and dc.entry_date = ce.entry_date
)

select * from inventory
