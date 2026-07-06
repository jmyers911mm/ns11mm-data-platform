/*
  ml_ticket_demand_features
  Sources: fct_ticket_availability + dim_date
  STATUS: Awaiting RAW data. Logic migrated from POC — no ref changes needed.
*/

{{ config(enabled=false,materialized='table', transient=true, tags=['daily', 'non-critical']) }}

with daily_demand as (
    select entry_date, ticket_type,
           sum(tickets_reserved)    as daily_reserved,
           sum(ticket_capacity)     as daily_capacity,
           round(sum(tickets_reserved)::float / nullif(sum(ticket_capacity),0) * 100, 2) as daily_utilization_pct,
           count(case when demand_level = 'Sold Out'                       then 1 end) as windows_sold_out,
           count(case when demand_level in ('Sold Out','High Demand')      then 1 end) as windows_high_demand,
           count(*)                 as total_windows
    from {{ ref('fct_ticket_availability') }}
    group by entry_date, ticket_type
),

with_features as (
    select d.*, dd.day_of_week as day_of_week_num, dd.day_of_week_name as day_name,
           dd.is_weekend, dd.month_of_year as month_num, dd.fiscal_year,
           lag(d.daily_reserved, 1) over (partition by d.ticket_type order by d.entry_date) as reserved_lag_1d,
           lag(d.daily_reserved, 7) over (partition by d.ticket_type order by d.entry_date) as reserved_lag_7d,
           avg(d.daily_reserved) over (partition by d.ticket_type order by d.entry_date rows between 6 preceding and current row) as reserved_7d_avg,
           avg(d.daily_reserved) over (partition by d.ticket_type order by d.entry_date rows between 29 preceding and current row) as reserved_30d_avg,
           stddev(d.daily_reserved) over (partition by d.ticket_type order by d.entry_date rows between 29 preceding and current row) as reserved_30d_stddev
    from daily_demand d
    left join {{ ref('dim_date') }} dd on d.entry_date = dd.date_id
)

select *, current_timestamp() as _feature_computed_at
from with_features
