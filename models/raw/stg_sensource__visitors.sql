-- Bronze staging: Sensource visitor counts
-- ---------------------------------------------------------------------------
-- Domain: attendance
-- Grain:  one row per key_date + key_facility + acp
-- Conforms seed_sensource_visitors (SensorData: entries/exits/passes by
-- facility). Feeds int_retail__visitors (conversion/per-cap) and true museum
-- attendance. ADR-001: rename/recast only. key_date is YYYYMMDD.
{{ config(materialized='view') }}

with source as (
    select * from {{ source('report_estate_seed', 'seed_sensource_visitors') }}
),
staged as (
    select
        try_to_date(key_date::varchar, 'YYYYMMDD')  as business_date,
        key_facility::integer                       as key_facility,
        acp::integer                                as acp_id,
        num_entry::number(18,0)                     as num_entry,
        num_exit::number(18,0)                      as num_exit,
        passes_scanned::integer                     as passes_scanned,
        _loaded_at
    from source
)
select * from staged
