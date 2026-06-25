/*
  fct_ticket_demand_benchmarks
  Source: fct_ticket_availability
  STATUS: Awaiting RAW data. Logic migrated from POC.
  90-day rolling benchmarks by ticket type, day-of-week, and entry window.
*/

{{ config(materialized='table', tags=['daily', 'critical']) }}

with historical as (
    select
        ticket_type, day_name, day_of_week_num, is_weekend,
        entry_window_start, tickets_reserved, ticket_capacity, utilization_pct
    from {{ ref('fct_ticket_availability') }}
    where entry_date >= dateadd('day', -90, current_date())
      and entry_date < current_date()
)

select
    ticket_type, day_name, day_of_week_num, is_weekend, entry_window_start,
    count(*)                                                as sample_days,
    round(avg(tickets_reserved), 1)                         as avg_reserved,
    round(median(tickets_reserved), 1)                      as median_reserved,
    min(tickets_reserved)                                   as min_reserved,
    max(tickets_reserved)                                   as max_reserved,
    round(stddev(tickets_reserved), 2)                      as stddev_reserved,
    round(percentile_cont(0.25) within group (order by tickets_reserved), 1) as p25_reserved,
    round(percentile_cont(0.75) within group (order by tickets_reserved), 1) as p75_reserved,
    round(percentile_cont(0.90) within group (order by tickets_reserved), 1) as p90_reserved,
    round(avg(ticket_capacity), 0)                          as avg_capacity,
    round(avg(utilization_pct), 2)                          as avg_utilization_pct,
    round(percentile_cont(0.90) within group (order by utilization_pct), 2) as p90_utilization_pct,
    case
        when avg(utilization_pct) >= 80 then 'Consistently High'
        when avg(utilization_pct) >= 50 then 'Moderate'
        when avg(utilization_pct) >= 20 then 'Low'
        else 'Very Low'
    end                                                     as typical_demand_level,
    round(avg(tickets_reserved) - 2 * stddev(tickets_reserved), 1) as lower_bound_2sd,
    round(avg(tickets_reserved) + 2 * stddev(tickets_reserved), 1) as upper_bound_2sd
from historical
group by 1, 2, 3, 4, 5
