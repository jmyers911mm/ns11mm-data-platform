-- Bronze staging: same-day product-level CounterPoint retail
-- ---------------------------------------------------------------------------
-- Domain: retail
-- Grain:  one row per store_id + doc_id + item_no + tkt_hour
-- Conforms seed_fact_todays_retail_product_data. Today's Sales product detail.
-- ADR-001: rename/recast only.
-- 8.1.0: tags=['intraday'] added (merges with the raw-layer daily/critical
-- tags) so the 300-second intraday statement timeout applies to the same-day
-- CounterPoint feed as well as to the marts built on it.
{{ config(materialized='view', tags=['intraday']) }}

with source as (
    select * from {{ source('report_estate_seed', 'seed_fact_todays_retail_product_data') }}
),
staged as (
    select
        try_to_date(key_date::varchar)          as business_date,
        tkt_hour::integer                       as hour_of_day,
        str_id::varchar                         as store_id,
        doc_id                                  as doc_id,
        item_no::varchar                        as item_no,
        cat_code::varchar                       as category_code,
        qty_sold::number(18,3)                  as quantity_sold,
        qty_on_hand::number(18,3)               as quantity_on_hand,
        qty_avail::number(18,3)                 as quantity_available,
        _loaded_at
    from source
)
select * from staged
