-- Bronze staging: hourly gate passes
-- ---------------------------------------------------------------------------
-- Domain: attendance
-- Grain:  one row per key_date + perhour
-- Conforms seed_fact_passes_by_hour (Galaxy1 hourly pass counts) into
-- snake_case. Feeds int_ / rpt_daily_attendance (replaces the stub seed).
-- ADR-001: rename/recast only.
{{ config(materialized='view') }}

with source as (
    select * from {{ source('report_estate_seed', 'seed_fact_passes_by_hour') }}
),
staged as (
    select
        try_to_date(key_date::varchar)          as business_date,
        perhour::integer                        as hour_of_day,
        passes::integer                         as passes,
        _loaded_at
    from source
)
select * from staged
