-- Bronze staging: Sensource attendance (pre-aggregated by area)
-- ---------------------------------------------------------------------------
-- Domain: attendance
-- Grain:  one row per key_date
-- Conforms seed_sensource_attendance. Source is ALREADY pivoted to named area
-- columns (memorial/museum attendance + memorial-only, store, store-Vesey area
-- counts) -- no facility mapping needed. Feeds rpt_attendance directly.
-- ADR-001: rename/recast only. key_date is YYYYMMDD.
{{ config(materialized='view') }}

with source as (
    select * from {{ source('report_estate_seed', 'seed_sensource_attendance') }}
),
staged as (
    select
        try_to_date(key_date::varchar, 'YYYYMMDD')  as business_date,
        mem_attendance::integer                     as mem_attendance,
        mus_attendance::integer                     as mus_attendance,
        memorial_only::integer                      as memorial_only,
        mus_store::integer                          as mus_store,
        mus_store_vesey::integer                    as mus_store_vesey,
        _loaded_at
    from source
)
select * from staged
