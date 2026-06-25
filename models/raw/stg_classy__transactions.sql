/*
  stg_classy__transactions
  Source: classy.raw_classy_transactions (NS11MM_DW_DEV.RAW)

  Classy REST API /organizations/{org_id}/transactions endpoint.
  Each row is a completed donation transaction.
*/

{{ config(materialized='view') }}

with source as (
    select _extracted_at, _record_id, _raw_data
    from {{ source('classy', 'raw_classy_transactions') }}
),

renamed as (
    select
        _extracted_at,
        _raw_data:id::varchar                              as transaction_id,
        _raw_data:status::varchar                          as transaction_status,
        _raw_data:type::varchar                            as transaction_type,
        _raw_data:campaign_id::varchar                     as campaign_id,
        _raw_data:member_id::varchar                       as donor_member_id,
        _raw_data:fundraising_page_id::varchar             as fundraising_page_id,
        _raw_data:fundraising_team_id::varchar             as fundraising_team_id,
        _raw_data:gross_amount::number(12,2)               as gross_amount,
        _raw_data:net_amount::number(12,2)                 as net_amount,
        _raw_data:fee_on_top::boolean                      as donor_covered_fee,
        _raw_data:fee::number(12,2)                        as processing_fee,
        _raw_data:currency_code::varchar                   as currency_code,
        _raw_data:frequency::varchar                       as donation_frequency,
        _raw_data:is_anonymous::boolean                    as is_anonymous,
        _raw_data:dedication::variant                      as dedication_raw,
        _raw_data:comment::varchar                         as donor_comment,
        _raw_data:payment_type::varchar                    as payment_type,
        _raw_data:created_at::timestamp_tz                 as created_at,
        _raw_data:updated_at::timestamp_tz                 as updated_at,
        {{ generate_hashdiff(['_record_id', '_extracted_at::varchar']) }} as hashdiff
    from source
)

select * from renamed
