/*
  silver_pos_retail
  Sources: stg_counterpoint__transactions + stg_shopify__orders
  STATUS: Awaiting RAW data and ADR-008 decision on retail source split.
  TODO: Once ADR-008 is resolved, decide whether to UNION CounterPoint
        and Shopify here or keep them separate Silver models.
  Logic migrated from POC with production refs.
*/

{{
    config(
        materialized='incremental',
        unique_key='transaction_id',
        incremental_strategy='merge',
        on_schema_change='append_new_columns',
        cluster_by=['transaction_date', 'item_category'],
        tags=['daily', 'critical']
    )
}}

-- CounterPoint in-person retail
select
    transaction_id,
    transaction_date,
    'counterpoint'                                          as retail_channel,
    item_number                                             as item_sku,
    item_description                                        as item_name,
    category_code                                           as item_category,
    quantity_sold                                           as quantity,
    unit_price,
    extended_price                                          as total_amount,
    discount_amount,
    case when discount_amount > 0 then true else false end  as is_discounted,
    round(case when extended_price > 0
        then discount_amount / (extended_price + discount_amount)
        else 0 end, 4)                                      as discount_pct,
    payment_code                                            as payment_method,
    clerk_id,
    null                                                    as customer_email,
    null                                                    as customer_phone,
    _extracted_at,
    hashdiff
from {{ ref('stg_counterpoint__line_items') }}

{% if is_incremental() %}
where _extracted_at > (select max(_extracted_at) from {{ this }})
{% endif %}

union all

-- Shopify online retail
select
    order_id                                                as transaction_id,
    created_at::date                                        as transaction_date,
    'shopify'                                               as retail_channel,
    null                                                    as item_sku,
    null                                                    as item_name,
    null                                                    as item_category,
    null                                                    as quantity,
    null                                                    as unit_price,
    total_price                                             as total_amount,
    total_discounts                                         as discount_amount,
    case when total_discounts > 0 then true else false end  as is_discounted,
    round(case when total_price > 0
        then total_discounts / (total_price + total_discounts)
        else 0 end, 4)                                      as discount_pct,
    payment_gateway                                         as payment_method,
    null                                                    as clerk_id,
    customer_email,
    customer_phone,
    _extracted_at,
    hashdiff
from {{ ref('stg_shopify__orders') }}

{% if is_incremental() %}
where _extracted_at > (select max(_extracted_at) from {{ this }})
{% endif %}
