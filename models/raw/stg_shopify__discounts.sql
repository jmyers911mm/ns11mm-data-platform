-- Bronze staging: Shopify discounts
-- ---------------------------------------------------------------------------
-- Domain: ecommerce (ADR-008)
-- Grain:  one row per order_id + discount_code
-- Conforms seed_fact_shopify_discounts into snake_case.
-- ADR-001: rename/recast only. key_date is YYYYMMDD; blank discount_code -> null.
{{ config(materialized='view') }}

with source as (
    select * from {{ source('report_estate_seed', 'seed_fact_shopify_discounts') }}
),
staged as (
    select
        try_to_date(key_date::varchar, 'YYYYMMDD')      as business_date,
        order_number::varchar                           as order_number,
        order_id::varchar                               as order_id,
        nullif(trim(discount_code), '')                 as discount_code,
        total_discount::number(18,4)                    as total_discount,
        _loaded_at
    from source
)
select * from staged
