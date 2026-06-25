/*
  rpt_revenue_bridge
  Sources: fct_daily_operations + dim_date
  STATUS: Awaiting RAW data. Logic migrated from POC.
*/

{{ config(materialized='table', tags=['daily', 'critical']) }}

with daily_revenue as (
    select
        ops.visit_date,
        dd.year_number          as year_num,
        dd.week_of_year,
        dd.fiscal_year,
        dd.quarter_of_year      as fiscal_quarter,
        dd.is_weekend,
        dd.is_commemoration_day,
        ops.ticket_revenue,
        ops.ticket_discounts,
        ops.tickets_sold,
        ops.ticket_transactions,
        ops.retail_revenue,
        ops.retail_discounts,
        ops.retail_transactions,
        ops.total_revenue,
        ops.total_visitors
    from {{ ref('fct_daily_operations') }} ops
    inner join {{ ref('dim_date') }} dd on ops.visit_date = dd.date_id
),

weekly_agg as (
    select
        year_num, week_of_year, fiscal_year, fiscal_quarter,
        min(visit_date)         as week_start_date,
        max(visit_date)         as week_end_date,
        count(distinct visit_date) as operating_days,
        sum(ticket_revenue)     as ticket_revenue_gross,
        sum(ticket_discounts)   as ticket_discount_amount,
        sum(ticket_revenue) - sum(ticket_discounts) as ticket_revenue_net,
        sum(tickets_sold)       as tickets_sold,
        sum(retail_revenue)     as retail_revenue_gross,
        sum(retail_discounts)   as retail_discount_amount,
        sum(retail_revenue) - sum(retail_discounts) as retail_revenue_net,
        sum(total_revenue)      as total_revenue_gross,
        sum(total_revenue) - sum(ticket_discounts) - sum(retail_discounts) as total_revenue_net,
        sum(total_visitors)     as total_visitors
    from daily_revenue
    where is_commemoration_day = false   -- exclude Sep 11 from revenue bridge
    group by year_num, week_of_year, fiscal_year, fiscal_quarter
)

select
    curr.*,
    lag(curr.total_revenue_gross) over (order by curr.week_start_date) as prior_week_revenue,
    curr.total_revenue_gross
        - lag(curr.total_revenue_gross) over (order by curr.week_start_date) as wow_revenue_change,
    current_timestamp() as _loaded_at
from weekly_agg curr
