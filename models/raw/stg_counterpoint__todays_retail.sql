-- Bronze staging: same-day hourly CounterPoint retail
-- ---------------------------------------------------------------------------
-- Domain: retail
-- Grain:  one row per store_id + doc_id + tkt_hour
-- Conforms seed_fact_todays_retail_data (real-time CP feed) into snake_case.
-- Feeds fct_today_sales_hourly (replaces the stub seed).
-- ADR-001: rename/recast only.
{{ config(materialized='view') }}

with source as (
    select * from {{ source('report_estate_seed', 'seed_fact_todays_retail_data') }}
),
staged as (
    select
        try_to_date(key_date::varchar)          as business_date,
        tkt_hour::integer                       as hour_of_day,
        doc_id                                  as doc_id,
        store_id::varchar                       as store_id,
        qty_sold::number(18,3)                  as quantity_sold,
        tkt_am_pm::varchar                      as ticket_am_pm,
        sales::number(18,2)                     as sales,
        cost::number(18,2)                      as cost,
        _loaded_at
    from source
)
select * from staged
