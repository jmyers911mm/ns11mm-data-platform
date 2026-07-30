-- Rename fiscal_year/fiscal_quarter to year/quarter for simplified calendar dimensions
/*
  fct_monthly_operations
  Sources: fct_daily_operations + dim_date
  STATUS: Awaiting RAW data. Logic migrated from POC.
*/

{{ config(enabled=false,materialized='table') }}

with daily as (
    select
        ops.visit_date, dd.year_number as year, dd.quarter_of_year as quarter,
        dd.year_number as year_num, dd.month_of_year as month_num, dd.month_name, dd.is_weekend,
        ops.total_visitors, ops.ticket_transactions, ops.tickets_sold,
        ops.ticket_revenue, ops.ticket_discounts, ops.retail_transactions,
        ops.retail_revenue, ops.retail_discounts, ops.total_revenue,
        ops.valid_scans, ops.rejected_scans, ops.identified_ticket_buyers
    from {{ ref('fct_daily_operations') }} ops
    left join {{ ref('dim_date') }} dd on ops.visit_date = dd.date_id
)

select
    year || '-' || lpad(month_num, 2, '0')          as year_month,
    year, quarter, year_num, month_num, month_name,
    count(distinct visit_date)                              as operating_days,
    count(distinct case when is_weekend then visit_date end) as weekend_days,
    sum(total_visitors)                                     as total_visitors,
    round(avg(total_visitors), 0)                           as avg_daily_visitors,
    max(total_visitors)                                     as peak_day_visitors,
    sum(ticket_transactions)                                as ticket_transactions,
    sum(tickets_sold)                                       as tickets_sold,
    sum(ticket_revenue)                                     as ticket_revenue,
    sum(ticket_discounts)                                   as ticket_discounts,
    sum(retail_transactions)                                as retail_transactions,
    sum(retail_revenue)                                     as retail_revenue,
    sum(retail_discounts)                                   as retail_discounts,
    sum(total_revenue)                                      as total_revenue,
    round(sum(total_revenue) / nullif(sum(total_visitors), 0), 2) as revenue_per_visitor,
    sum(valid_scans)                                        as valid_scans,
    sum(rejected_scans)                                     as rejected_scans,
    current_timestamp()                                     as _loaded_at
from daily
group by year, quarter, year_num, month_num, month_name
