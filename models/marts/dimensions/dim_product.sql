/*
  dim_product
  Source: stg_counterpoint__imitem
  Grain: one row per item_no (CounterPoint retail SKU)

  Retail product dimension for museum store, carts, ecommerce. Derives price_tier
  and product_group from category/price attributes.
*/

{{ config(materialized='table', tags=['daily', 'critical']) }}

with items as (
    select * from {{ ref('stg_counterpoint__imitem') }}
)

select
    item_no                             as product_key,
    item_no,
    trim(description)                   as item_description,
    trim(long_description)              as long_description,
    category_code,
    subcategory_code,
    item_type,
    barcode,
    regular_price,
    price_1                             as current_price,
    last_cost,
    is_taxable,
    is_discountable,
    status,
    item_vendor_no                      as vendor_no,
    is_ecommerce_item                   as is_ecommerce,
    case
        when regular_price >= 50 then 'Premium'
        when regular_price >= 20 then 'Mid-Range'
        when regular_price > 0   then 'Value'
        else 'Unpriced'
    end                                 as price_tier,
    current_timestamp()                 as _loaded_at
from items
