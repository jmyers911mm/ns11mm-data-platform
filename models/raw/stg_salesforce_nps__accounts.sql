/*
  stg_salesforce_nps__accounts
  Source: salesforce_nps.raw_salesforce_nps_account (NS11MM_DW_DEV.RAW)
*/

{{ config(materialized='view') }}

with source as (
    select _extracted_at, _record_id, _raw_data
    from {{ source('salesforce_nps', 'raw_salesforce_nps_account') }}
),

renamed as (
    select
        _extracted_at,
        _raw_data:Id::varchar                              as account_id,
        _raw_data:Name::varchar                            as account_name,
        _raw_data:Type::varchar                            as account_type,
        _raw_data:BillingCity::varchar                     as billing_city,
        _raw_data:BillingState::varchar                    as billing_state,
        _raw_data:BillingCountry::varchar                  as billing_country,
        _raw_data:CreatedDate::timestamp_tz                as created_at,
        _raw_data:LastModifiedDate::timestamp_tz           as last_modified_at,
        {{ generate_hashdiff(['_record_id', '_extracted_at::varchar']) }} as hashdiff
    from source
)

select * from renamed
