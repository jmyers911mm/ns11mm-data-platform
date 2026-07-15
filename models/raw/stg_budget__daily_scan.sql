-- Bronze staging: daily-scan budget / forecast (by market segment)
-- ---------------------------------------------------------------------------
-- Domain: attendance / scanning (budget)
-- Grain:  one row per key_date (segment columns pivoted wide in source)
-- Conforms seed_dsr_budget (fact_dsr_forecasts). Wide: a column per segment.
-- fct_daily_scan can unpivot to segment grain. ADR-001: rename/recast only.
-- key_date YYYYMMDD; forecast values are decimals; 'NULL' strings nullified.
{{ config(materialized='view') }}

with source as (
    select * from {{ source('report_estate_seed', 'seed_dsr_budget') }}
),
staged as (
    select
        try_to_date(key_date::varchar, 'YYYYMMDD')                    as business_date,
        try_to_decimal(nullif(advance::varchar,'NULL'),18,4)          as advance,
        try_to_decimal(nullif(mobile::varchar,'NULL'),18,4)           as mobile,
        try_to_decimal(nullif(walk_up::varchar,'NULL'),18,4)          as walk_up,
        try_to_decimal(nullif(self_organized_groups::varchar,'NULL'),18,4) as self_organized_groups,
        try_to_decimal(nullif(tour_travel::varchar,'NULL'),18,4)      as tour_travel,
        try_to_decimal(nullif(citypass::varchar,'NULL'),18,4)         as citypass,
        try_to_decimal(nullif(c3_citypass::varchar,'NULL'),18,4)      as c3_citypass,
        try_to_decimal(nullif(new_york_pass::varchar,'NULL'),18,4)    as new_york_pass,
        try_to_decimal(nullif(partners::varchar,'NULL'),18,4)         as partners,
        try_to_decimal(nullif(explorer_pass::varchar,'NULL'),18,4)    as explorer_pass,
        try_to_decimal(nullif(sightseeing_pass::varchar,'NULL'),18,4) as sightseeing_pass,
        try_to_decimal(nullif(school_groups::varchar,'NULL'),18,4)    as school_groups,
        try_to_decimal(nullif(membership::varchar,'NULL'),18,4)       as membership,
        try_to_decimal(nullif(comps::varchar,'NULL'),18,4)            as comps,
        try_to_decimal(nullif(gocity::varchar,'NULL'),18,4)           as gocity,
        try_to_decimal(nullif(total_tickets::varchar,'NULL'),18,4)    as total_tickets,
        _loaded_at
    from source
)
select * from staged
