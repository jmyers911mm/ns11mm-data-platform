-- Rename fiscal_year to year for simplified calendar dimensions
-- Co-authored with CoCo
/*
  fct_marketing_sales_daily
  Sources: fct_marketing_channel_summary + fct_ticket_sales + fct_retail_line_items
  STATUS: Awaiting RAW data. Logic migrated from POC.
*/

{{ config(enabled=false,materialized='table', cluster_by=['report_date']) }}

with marketing as (
    select report_date, channel, is_paid, sum(impressions) as impressions,
           sum(clicks) as clicks, sum(spend) as spend, sum(conversions) as conversions
    from {{ ref('fct_marketing_channel_summary') }}
    group by report_date, channel, is_paid
),
ticket_sales as (
    select transaction_date as report_date,
           count(distinct transaction_id) as ticket_transactions,
           sum(quantity) as tickets_sold,
           sum(total_amount) as ticket_revenue,
           sum(discount_amount) as ticket_discounts
    from {{ ref('fct_ticket_sales') }}
    group by transaction_date
),
retail_sales as (
    select transaction_date as report_date,
           count(distinct transaction_id) as retail_transactions,
           sum(total_amount) as retail_revenue,
           sum(discount_amount) as retail_discounts
    from {{ ref('fct_retail_line_items') }}
    group by transaction_date
)

select
    m.report_date, dd.year_number as year, dd.month_name, dd.day_of_week_name as day_name, dd.is_weekend,
    m.channel, m.is_paid, m.impressions, m.clicks, m.spend, m.conversions,
    coalesce(ts.ticket_transactions, 0) as ticket_transactions,
    coalesce(ts.tickets_sold, 0) as tickets_sold,
    coalesce(ts.ticket_revenue, 0) as ticket_revenue,
    coalesce(ts.ticket_discounts, 0) as ticket_discounts,
    coalesce(rs.retail_transactions, 0) as retail_transactions,
    coalesce(rs.retail_revenue, 0) as retail_revenue,
    coalesce(rs.retail_discounts, 0) as retail_discounts,
    coalesce(ts.ticket_revenue, 0) + coalesce(rs.retail_revenue, 0) as total_sales_revenue,
    case when m.spend > 0
        then (coalesce(ts.ticket_revenue, 0) + coalesce(rs.retail_revenue, 0)) / m.spend
        else null end as revenue_to_spend_ratio,
    current_timestamp() as _loaded_at
from marketing m
left join ticket_sales  ts on m.report_date = ts.report_date
left join retail_sales  rs on m.report_date = rs.report_date
left join {{ ref('dim_date') }} dd on m.report_date = dd.date_id
