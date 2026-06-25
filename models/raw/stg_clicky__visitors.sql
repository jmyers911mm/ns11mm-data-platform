/*
  stg_clicky__visitors
  Source: clicky.raw_clicky_visitors (NS11MM_DW_DEV.RAW)

  Clicky API /api/stats/4 endpoint with type=visitors.
  Each row represents daily visitor stats for the site.
*/

{{ config(materialized='view') }}

with source as (
    select _extracted_at, _record_id, _raw_data
    from {{ source('clicky', 'raw_clicky_visitors') }}
),

renamed as (
    select
        _extracted_at,
        _raw_data:date::date                               as stat_date,
        _raw_data:value::integer                           as visitors,
        _raw_data:type::varchar                            as stat_type,
        {{ generate_hashdiff(['_record_id', '_extracted_at::varchar']) }} as hashdiff
    from source
)

select * from renamed
