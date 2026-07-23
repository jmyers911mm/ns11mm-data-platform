/*
  dim_facility
  Source: seed_facility_area (dbt seed)
  Grain: one row per key_facility (911dw selling-area surrogate key)

  Conformed facility/area dimension. Single home for the key_facility ->
  area_name / area_group / is_selling / facility_group mapping that was
  previously re-selected inline in fct_retail_daily, fct_retail_performance,
  fct_today_sales_hourly, and dim_store, and whose facility_group name was an
  inline CASE in int_counterpoint__retail_lines. Consumers left join this and
  keep their own 'Unmapped' / 'other' fallback for facilities that appear in
  fact data but are not (yet) in the seed.
*/

{{ config(materialized='table', tags=['daily', 'critical']) }}

with areas as (
    select * from {{ ref('seed_facility_area') }}
)

select
    key_facility                        as facility_key,
    key_facility,
    area_name,
    area_group,
    facility_group,
    is_selling,
    true                                as is_active,
    current_timestamp()                 as _loaded_at
from areas
