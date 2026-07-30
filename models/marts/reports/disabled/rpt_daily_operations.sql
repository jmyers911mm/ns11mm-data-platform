-- Rename fiscal_year/fiscal_quarter to year/quarter for simplified calendar dimensions
/*
  rpt_daily_operations
  Sources: fct_daily_operations + dim_date
  STATUS: Awaiting RAW data. Logic migrated from POC.
*/

{{ config(enabled=false,materialized='table') }}

select
    ops.visit_date,
    dd.day_of_week_name                                     as day_name,
    dd.month_name,
    dd.year_number                                          as year_num,
    dd.year_number                                          as year,
    dd.quarter_of_year                                      as quarter,
    dd.is_weekend,
    dd.is_commemoration_day,
    ops.total_visitors,
    ops.valid_scans,
    ops.rejected_scans,
    ops.gates_active,
    ops.ticket_transactions,
    ops.tickets_sold,
    ops.ticket_revenue,
    ops.ticket_discounts,
    ops.ticket_revenue - ops.ticket_discounts               as net_ticket_revenue,
    div0(ops.ticket_revenue, nullif(ops.ticket_transactions, 0)) as ticket_aov,
    div0(ops.tickets_sold, nullif(ops.ticket_transactions, 0))   as avg_tickets_per_txn,
    ops.retail_transactions,
    ops.retail_revenue,
    ops.retail_discounts,
    ops.retail_revenue - ops.retail_discounts               as net_retail_revenue,
    div0(ops.retail_revenue, nullif(ops.retail_transactions, 0)) as retail_aov,
    ops.total_revenue,
    ops.total_revenue - ops.ticket_discounts - ops.retail_discounts as net_total_revenue,
    ops.retail_revenue_per_visitor,
    div0(ops.total_revenue, nullif(ops.total_visitors, 0))  as revenue_per_visitor,
    ops.identified_ticket_buyers,
    div0(ops.identified_ticket_buyers, nullif(ops.ticket_transactions, 0)) as identification_rate
from {{ ref('fct_daily_operations') }} ops
left join {{ ref('dim_date') }} dd on ops.visit_date = dd.date_id
