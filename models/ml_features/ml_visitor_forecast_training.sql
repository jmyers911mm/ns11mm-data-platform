/*
  ml_visitor_forecast_training
  Source: fct_daily_operations
  STATUS: Awaiting RAW data. Logic migrated from POC.
  Feeds Snowflake ML FORECAST — see macros/operations/create_ticket_demand_forecast.sql
*/

{{ config(materialized='table', tags=['daily', 'non-critical']) }}

select
    visit_date::timestamp_ntz                              as ds,
    total_visitors                                         as y,
    day_of_week_name                                       as day_of_week,
    case when extract(dow from visit_date) in (0, 6) then 1 else 0 end as is_weekend,
    extract(month from visit_date)                         as month_num,
    ticket_revenue + retail_revenue                        as total_revenue,
    ticket_transactions,
    gates_active
from {{ ref('fct_daily_operations') }}
left join {{ ref('dim_date') }} dd on visit_date = dd.date_id
where total_visitors > 0
order by visit_date
