/*
  dim_store
  Source: seed_retail_store_facility (dbt seed) + dim_facility
  Grain: one row per store_id (CounterPoint register/store)

  Maps CounterPoint store IDs to facility names and locations using the
  seed_retail_store_facility mapping table. store_type is sourced from the
  conformed dim_facility (single home for key_facility -> area_group) rather
  than re-reading seed_facility_area here.
*/

{{ config(materialized='table', tags=['daily', 'critical']) }}

with stores as (
    select
        store_id,
        min(key_facility)               as key_facility,
        min(facility_name)              as store_name,
        min(notes)                      as store_location
    from {{ ref('seed_retail_store_facility') }}
    group by store_id
)

select
    s.store_id                          as store_key,
    s.store_id::text                    as store_id,
    s.store_name,
    s.store_location,
    f.area_group                        as store_type,
    true                                as is_active,
    current_timestamp()                 as _loaded_at
from stores s
left join {{ ref('dim_facility') }} f on s.key_facility = f.key_facility
