-- Bronze staging: Shopify cost values (order-level P&L)
-- ---------------------------------------------------------------------------
-- Domain: ecommerce (ADR-008)
-- Grain:  one row per order_id
-- Conforms seed_fact_shopify_cost_values into snake_case. Order-level gross/
-- net/profit for ecom profitability.
-- ADR-001: rename/recast only. key_date is YYYYMMDD.
{{ config(materialized='view') }}

with source as (
    select * from {{ source('report_estate_seed', 'seed_fact_shopify_cost_values') }}
),
staged as (
    select
        try_to_date(key_date::varchar, 'YYYYMMDD')      as business_date,
        order_id::varchar                               as order_id,
        financial_status::varchar                       as financial_status,
        gross_sales::number(18,4)                       as gross_sales,
        shipping::number(18,4)                          as shipping,
        discounts::number(18,4)                         as discounts,
        tax::number(18,4)                               as tax,
        net_sales::number(18,4)                         as net_sales,
        cost::number(18,4)                              as cost,
        profit::number(18,4)                            as profit,
        _loaded_at
    from source
)
select * from staged
