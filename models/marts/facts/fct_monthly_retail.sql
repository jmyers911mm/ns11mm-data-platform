/*
  fct_monthly_retail
  Sources: fct_retail_line_items + dim_date
  STATUS: Awaiting RAW data. Logic migrated from POC.
  Note: POC used deprecated fct_retail_performance — updated to use fct_retail_line_items.
*/

{{ config(materialized='table') }}

with daily as (
    select
        r.transaction_date, dd.fiscal_year, dd.quarter_of_year as fiscal_quarter,
        dd.year_number as year_num, dd.month_of_year as month_num, dd.month_name,
        r.item_category,
        count(distinct r.transaction_id) as transaction_count,
        sum(r.quantity) as items_sold,
        sum(r.total_amount) as gross_revenue,
        sum(r.discount_amount) as total_discounts,
        sum(r.total_amount) - sum(r.discount_amount) as net_revenue,
        count(case when r.is_discounted then 1 end) as discounted_transactions
    from {{ ref('fct_retail_line_items') }} r
    left join {{ ref('dim_date') }} dd on r.transaction_date = dd.date_id
    group by r.transaction_date, dd.fiscal_year, dd.quarter_of_year, dd.year_number,
             dd.month_of_year, dd.month_name, r.item_category
)

select
    year_num || '-' || lpad(month_num, 2, '0') || '-' || item_category as month_category,
    fiscal_year, fiscal_quarter, year_num, month_num, month_name, item_category,
    count(distinct transaction_date)                        as selling_days,
    sum(transaction_count)                                  as transaction_count,
    sum(items_sold)                                         as items_sold,
    sum(gross_revenue)                                      as gross_revenue,
    sum(total_discounts)                                    as total_discounts,
    sum(net_revenue)                                        as net_revenue,
    round(sum(net_revenue) / nullif(count(distinct transaction_date), 0), 2) as avg_daily_revenue,
    round(sum(items_sold)::float / nullif(sum(transaction_count), 0), 2) as avg_items_per_transaction,
    sum(discounted_transactions)                            as discounted_transactions,
    current_timestamp()                                     as _loaded_at
from daily
group by fiscal_year, fiscal_quarter, year_num, month_num, month_name, item_category
