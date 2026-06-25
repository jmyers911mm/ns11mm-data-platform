/*
  stg_salesforce_nps__contacts
  Source: salesforce_nps.raw_salesforce_nps_contact (NS11MM_DW_DEV.RAW)

  Salesforce NPS Contact object. Field names are Salesforce API names (PascalCase).
  The pipeline extracts: Id, FirstName, LastName, Email, Phone, AccountId,
  OwnerId, CreatedDate, LastModifiedDate.
*/

{{ config(materialized='view') }}

with source as (
    select _extracted_at, _record_id, _raw_data
    from {{ source('salesforce_nps', 'raw_salesforce_nps_contact') }}
),

renamed as (
    select
        _extracted_at,
        _raw_data:Id::varchar                              as contact_id,
        _raw_data:FirstName::varchar                       as first_name,
        _raw_data:LastName::varchar                        as last_name,
        _raw_data:Email::varchar                           as email,
        _raw_data:Phone::varchar                           as phone,
        _raw_data:AccountId::varchar                       as account_id,
        _raw_data:OwnerId::varchar                         as owner_id,
        _raw_data:CreatedDate::timestamp_tz                as created_at,
        _raw_data:LastModifiedDate::timestamp_tz           as last_modified_at,
        {{ generate_hashdiff(['_record_id', '_extracted_at::varchar']) }} as hashdiff
    from source
)

select * from renamed
