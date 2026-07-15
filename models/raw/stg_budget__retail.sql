-- Bronze staging: retail budget / forecast
-- ---------------------------------------------------------------------------
-- Domain: retail (budget)
-- Grain:  one row per key_date + key_facility
-- Conforms seed_retail_budget (fact_retail_forecasts). Feeds the retail *_budget
-- seams. ADR-005 budget source. ADR-001: rename/recast only. key_date YYYYMMDD.
-- Note: key_facility is a numeric facility code (e.g. 1003), not a name.
{{ config(materialized='view') }}

with source as (
    select * from {{ source('report_estate_seed', 'seed_retail_budget') }}
),
staged as (
    select
        try_to_date(key_date::varchar, 'YYYYMMDD')  as business_date,
        key_facility::integer                       as key_facility,
        profit_from_retail::number(18,4)            as profit_budget,
        revenue::number(18,4)                       as revenue_budget,
        donations::number(18,4)                     as donations_budget,
        visitors::integer                           as visitors_budget,
        customers::integer                          as customers_budget,
        average_sale::number(18,4)                  as average_sale_budget,
        capture_rate::number(18,6)                  as capture_rate_budget,
        conversion_rate::number(18,6)               as conversion_rate_budget,
        museum_attendance::integer                  as museum_attendance_budget,
        try_to_decimal(nullif(avg_don_mem_only_vis::varchar,'NULL'), 18, 4) as avg_donation_per_mem_visitor_budget,
        _loaded_at
    from source
)
select * from staged
