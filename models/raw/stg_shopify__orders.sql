-- Bronze staging: Shopify orders
-- ---------------------------------------------------------------------------
-- Domain: ecommerce (ADR-008)
-- Grain:  one row per order_id + orderline_id
-- Conforms seed_fact_shopify_orders into snake_case. Feeds the ecom order/
-- donation measures (Website Commerce, retail ecom split).
-- ADR-001: rename/recast only.
-- Notes: key_date is YYYYMMDD; id columns kept as varchar (large ids, no math);
-- refund_* columns carry literal 'NULL' strings from export -> nullified.
{{ config(materialized='view') }}

with source as (
    select * from {{ source('report_estate_seed', 'seed_fact_shopify_orders') }}
),
staged as (
    select
        try_to_date(key_date::varchar, 'YYYYMMDD')      as business_date,
        order_number::varchar                           as order_number,
        order_id::varchar                               as order_id,
        orderline_id::varchar                           as order_line_id,
        financial_status::varchar                       as financial_status,
        key_user::varchar                               as customer_key,
        key_category::integer                           as category_key,
        key_item_descr::varchar                         as item_description_key,
        quantity::number(18,3)                          as quantity,
        price::number(18,4)                             as price,
        total_revenue::number(18,4)                     as total_revenue,
        cost::number(18,4)                              as cost,
        total_cost::number(18,4)                        as total_cost,
        try_to_decimal(nullif(refund_quantity::varchar,'NULL'), 18, 3) as refund_quantity,
        try_to_decimal(nullif(refund_price::varchar,'NULL'), 18, 4)    as refund_price,
        try_to_decimal(nullif(total_refund::varchar,'NULL'), 18, 4)    as total_refund,
        _loaded_at
    from source
)
select * from staged
