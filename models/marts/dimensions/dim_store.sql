/*
  dim_store
  Source: seed_retail_store_facility (dbt seed)
  Grain: one row per store_id (CounterPoint register/store)

  Maps CounterPoint store IDs to facility names and locations using the
  seed_retail_store_facility mapping table.
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
),

areas as (
    select
        key_facility,
        area_name,
        area_group
    from {{ ref('seed_facility_area') }}
)

select
    s.store_id                          as store_key,
    s.store_id::text                    as store_id,
    s.store_name,
    s.store_location,
    a.area_group                        as store_type,
    true                                as is_active,
    current_timestamp()                 as _loaded_at
from stores s
left join areas a on s.key_facility = a.key_facility
