/*
  rpt_retail_performance
  Sources: fct_retail_line_items + dim_date + dim_product + dim_payment_method + dim_customer
  STATUS: Awaiting RAW data. Logic migrated from POC.
*/

{{ config(materialized='table') }}

select
    r.transaction_id,
    r.transaction_date,
    r.retail_channel,
    dd.day_of_week_name                                    as day_name,
    dd.month_name,
    dd.fiscal_year,
    dd.is_weekend,
    r.item_sku,
    r.item_name,
    r.item_category,
    dp.product_group,
    dp.price_tier                                          as product_price_tier,
    dp.standard_price                                      as product_standard_price,
    r.quantity,
    r.unit_price,
    r.total_amount,
    r.discount_amount,
    r.is_discounted,
    r.discount_pct,
    r.payment_method,
    pm.payment_method_name,
    pm.payment_category,
    pm.is_electronic,
    r.customer_id,
    c.full_name                                            as customer_name,
    c.customer_segment,
    c.membership_type                                      as customer_membership_type
from {{ ref('fct_retail_line_items') }} r
left join {{ ref('dim_date') }}           dd on r.transaction_date = dd.date_id
left join {{ ref('dim_product') }}        dp on r.item_sku = dp.product_id
left join {{ ref('dim_payment_method') }} pm on r.payment_method = pm.payment_method_id
left join {{ ref('dim_customer') }}       c  on r.customer_id = c.customer_id
