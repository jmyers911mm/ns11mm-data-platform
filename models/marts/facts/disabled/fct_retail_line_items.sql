/*
  fct_retail_line_items
  Sources: int_pos_retail, dim_customer, dim_product
  STATUS: Awaiting RAW data. Logic migrated from POC.
*/

{{ config(enabled=false,materialized='table', cluster_by=['transaction_date', 'item_category']) }}

with retail as (
    select * from {{ ref('int_pos_retail') }}
),

customer_lookup as (
    select customer_id, primary_email, primary_phone
    from {{ ref('dim_customer') }}
)

select
    r.transaction_id,
    r.transaction_date,
    r.retail_channel,
    r.item_sku,
    r.item_name,
    r.item_category,
    r.quantity,
    r.unit_price,
    r.total_amount,
    r.discount_amount,
    r.is_discounted,
    r.discount_pct,
    r.payment_method,
    r.customer_email,
    r.customer_phone,
    coalesce(ce.customer_id, cp.customer_id)               as customer_id,
    current_timestamp()                                     as _loaded_at
from retail r
left join customer_lookup ce on r.customer_email = ce.primary_email and r.customer_email is not null
left join customer_lookup cp on r.customer_phone = cp.primary_phone and r.customer_phone is not null and ce.customer_id is null
