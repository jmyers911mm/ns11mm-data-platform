-- Bronze staging: recurring online donation/membership (Drupal commerce)
-- ---------------------------------------------------------------------------
-- Domain: ecommerce / fundraising
-- Grain:  one row per order_id + sku
-- Conforms seed_fact_website_recurring_data_db. Feeds rpt_website_commerce
-- (replaces the ecom stub). PII note: `email` is a direct identifier -- mark
-- restricted in schema.yml if this is surfaced downstream.
-- ADR-001: rename/recast only.
{{ config(materialized='view') }}

with source as (
    select * from {{ source('report_estate_seed', 'seed_fact_website_recurring_data') }}
),
staged as (
    select
        order_id                                as order_id,
        sku::varchar                            as sku,
        title::varchar                          as title,
        order_type::varchar                     as order_type,
        order_status::varchar                   as order_status,
        email::varchar                          as email,               -- PII
        try_to_timestamp(date_created::varchar)   as created_at,
        try_to_timestamp(date_modified::varchar)  as modified_at,
        try_to_timestamp(date_completed::varchar) as completed_at,
        quantity::number(18,3)                  as quantity,
        revenue::number(18,2)                   as revenue,
        purchase_order_comment::varchar         as purchase_order_comment,
        _loaded_at
    from source
)
select * from staged
