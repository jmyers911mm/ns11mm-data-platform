/*
  dim_product
  Source: silver_pos_retail
  STATUS: Awaiting RAW data.
  Logic migrated from POC.
*/

{{ config(enabled=false,materialized='table') }}

with counterpoint_products as (
    select distinct
        item_sku    as product_id,
        item_name   as product_name,
        item_category as category,
        unit_price  as standard_price,
        'counterpoint' as source_system
    from {{ ref('silver_pos_retail') }}
    where retail_channel = 'counterpoint'
),

shopify_products as (
    select distinct
        product_id,
        product_title   as product_name,
        product_type    as category,
        null::float     as standard_price,
        'shopify'       as source_system
    from {{ ref('stg_shopify__products') }}
)

select
    product_id,
    product_name,
    category,
    standard_price,
    source_system,
    case
        when standard_price >= 30 then 'Premium'
        when standard_price >= 15 then 'Mid-Range'
        else 'Value'
    end as price_tier,
    case category
        when 'Books'       then 'Educational'
        when 'Art Prints'  then 'Educational'
        when 'Kids'        then 'Family'
        when 'Games'       then 'Family'
        when 'Souvenirs'   then 'Keepsake'
        when 'Accessories' then 'Wearable'
        when 'Jewelry'     then 'Wearable'
        else 'Other'
    end as product_group,
    current_timestamp() as _loaded_at
from counterpoint_products
union all
select product_id, product_name, category, standard_price, source_system,
       null, null, current_timestamp()
from shopify_products
