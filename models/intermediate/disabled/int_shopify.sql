/*
  int_shopify
  Source: stg_shopify__orders
  STATUS: Awaiting RAW data. New model — no POC equivalent.
*/

{{
    config(
        enabled=false,
        materialized='incremental',
        unique_key='order_id',
        incremental_strategy='merge',
        on_schema_change='append_new_columns',
        tags=['daily', 'critical']
    )
}}

select
    order_id,
    order_number,
    order_name,
    created_at::date                                        as order_date,
    financial_status,
    fulfillment_status,
    currency,
    total_price,
    subtotal_price,
    total_discounts,
    total_tax,
    shipping_price,
    total_price - total_discounts                           as net_revenue,
    case when total_discounts > 0 then true else false end  as is_discounted,
    round(case when total_price > 0
        then total_discounts / total_price else 0 end, 4)  as discount_pct,
    shopify_customer_id,
    customer_email,
    customer_phone,
    case when customer_email is not null then true else false end as has_email,
    customer_orders_count,
    customer_total_spent,
    payment_gateway,
    order_source,
    referring_site,
    billing_city,
    billing_country,
    shipping_city,
    shipping_country,
    is_test_order,
    created_at,
    updated_at,
    hashdiff,
    _extracted_at
from {{ ref('stg_shopify__orders') }}
where is_test_order = false or is_test_order is null

{% if is_incremental() %}
and _extracted_at > (select max(_extracted_at) from {{ this }})
{% endif %}
