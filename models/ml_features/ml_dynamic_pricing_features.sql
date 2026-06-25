/*
  ml_dynamic_pricing_features
  Sources: fct_ticket_availability + fct_ticket_demand_benchmarks
  STATUS: Awaiting RAW data. Logic migrated from POC — no ref changes needed.
*/

{{ config(materialized='table', tags=['daily', 'non-critical']) }}

with availability as (
    select entry_date, entry_window_start, ticket_type, ticket_capacity,
           tickets_reserved, tickets_available, utilization_pct, demand_level,
           day_name, day_of_week_num, is_weekend, fiscal_year
    from {{ ref('fct_ticket_availability') }}
),

benchmarks as (
    select ticket_type, day_of_week_num, entry_window_start,
           avg_reserved, median_reserved, p90_reserved,
           avg_utilization_pct, stddev_reserved, lower_bound_2sd, upper_bound_2sd
    from {{ ref('fct_ticket_demand_benchmarks') }}
)

select
    a.entry_date, a.entry_window_start, a.ticket_type,
    a.ticket_capacity, a.tickets_reserved, a.utilization_pct,
    a.day_of_week_num, a.is_weekend,
    extract(month from a.entry_date)                       as month_num,
    datediff('day', current_date(), a.entry_date)          as days_until_entry,
    coalesce(b.avg_reserved, 0)                            as benchmark_avg_demand,
    coalesce(b.p90_reserved, 0)                            as benchmark_p90_demand,
    coalesce(b.avg_utilization_pct, 0)                     as benchmark_avg_utilization,
    div0(a.tickets_reserved - coalesce(b.avg_reserved, 0),
         nullif(b.stddev_reserved, 0))                     as demand_z_score,
    case
        when a.utilization_pct >= 90 then 'surge'
        when a.utilization_pct >= 70 then 'high'
        when a.utilization_pct >= 40 then 'normal'
        else 'low'
    end                                                    as demand_band,
    case
        when a.utilization_pct >= 90 then 1.25
        when a.utilization_pct >= 70 then 1.10
        when a.utilization_pct <= 20 then 0.85
        else 1.00
    end                                                    as suggested_price_multiplier,
    current_timestamp()                                    as _feature_computed_at
from availability a
left join benchmarks b
    on  a.ticket_type       = b.ticket_type
    and a.day_of_week_num   = b.day_of_week_num
    and a.entry_window_start = b.entry_window_start
