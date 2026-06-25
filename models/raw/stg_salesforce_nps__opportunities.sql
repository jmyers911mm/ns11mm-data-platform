/*
  stg_salesforce_nps__opportunities
  Source: salesforce_nps.raw_salesforce_nps_opportunity (NS11MM_DW_DEV.RAW)
*/

{{ config(materialized='view') }}

with source as (
    select _extracted_at, _record_id, _raw_data
    from {{ source('salesforce_nps', 'raw_salesforce_nps_opportunity') }}
),

renamed as (
    select
        _extracted_at,
        _raw_data:Id::varchar                              as opportunity_id,
        _raw_data:Name::varchar                            as opportunity_name,
        _raw_data:AccountId::varchar                       as account_id,
        _raw_data:Amount::number(14,2)                     as amount,
        _raw_data:StageName::varchar                       as stage_name,
        _raw_data:Type::varchar                            as opportunity_type,
        _raw_data:CloseDate::date                          as close_date,
        _raw_data:CreatedDate::timestamp_tz                as created_at,
        _raw_data:LastModifiedDate::timestamp_tz           as last_modified_at,
        {{ generate_hashdiff(['_record_id', '_extracted_at::varchar']) }} as hashdiff
    from source
)

select * from renamed
