/*
  stg_vena__budget
  Source: vena.raw_vena_budget (NS11MM_DW_DEV.RAW)

  Vena Solutions model export. The exact field names depend on the
  model structure and dimension names configured in Vena.

  TODO: Populate MODELS dict in pipelines/vena/pipeline.py first.
  TODO: Confirm field names with Finance team after first export.
  Table name in RAW may differ from raw_vena_budget — update sources.yml
  to match actual model export name once known.
*/

{{ config(materialized='view') }}

with source as (
    select _extracted_at, _record_id, _raw_data
    from {{ source('vena', 'raw_vena_budget') }}
),

renamed as (
    select
        _extracted_at,
        -- Core budget dimensions (confirm field names with Finance team)
        _raw_data:account::varchar                         as account,
        _raw_data:department::varchar                      as department,
        _raw_data:fund::varchar                            as fund,
        _raw_data:project::varchar                         as project,
        _raw_data:period::varchar                          as budget_period,
        _raw_data:fiscal_year::varchar                     as fiscal_year,
        _raw_data:scenario::varchar                        as scenario,
        _raw_data:version::varchar                         as plan_version,
        -- Budget values
        _raw_data:amount::number(14,2)                     as budget_amount,
        _raw_data:currency::varchar                        as currency,
        {{ generate_hashdiff(['_record_id', '_extracted_at::varchar']) }} as hashdiff
    from source
)

select * from renamed
