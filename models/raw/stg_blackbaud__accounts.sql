/*
  stg_blackbaud__accounts
  Source: blackbaud.raw_blackbaud_nxt_accounts (NS11MM_DW_DEV.RAW)

  Blackbaud SKY API Financial Edge NXT /generalledger/v1/accounts endpoint.
  Returns chart of accounts entries.
*/

{{ config(materialized='view') }}

with source as (
    select _extracted_at, _record_id, _raw_data
    from {{ source('blackbaud', 'raw_blackbaud_nxt_accounts') }}
),

renamed as (
    select
        _extracted_at,
        _raw_data:id::varchar                              as account_id,
        _raw_data:account_number::varchar                  as account_number,
        _raw_data:description::varchar                     as account_description,
        _raw_data:account_type::varchar                    as account_type,
        _raw_data:account_class::varchar                   as account_class,
        _raw_data:normal_balance::varchar                  as normal_balance,
        _raw_data:cashflow_code::varchar                   as cashflow_code,
        _raw_data:budget_class::varchar                    as budget_class,
        _raw_data:restrict_projects::boolean               as restrict_projects,
        _raw_data:inactive::boolean                        as is_inactive,
        _raw_data:date_added::timestamp_tz                 as date_added,
        _raw_data:date_modified::timestamp_tz              as date_modified,
        _raw_data:added_by::varchar                        as added_by,
        _raw_data:modified_by::varchar                     as modified_by,
        {{ generate_hashdiff(['_record_id', '_extracted_at::varchar']) }} as hashdiff
    from source
)

select * from renamed
