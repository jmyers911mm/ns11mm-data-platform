/*
  stg_blackbaud__journal_entries
  Source: blackbaud.raw_blackbaud_nxt_journalentries (NS11MM_DW_DEV.RAW)

  Blackbaud SKY API /generalledger/v1/journalentries endpoint.
  NOTE: The Blackbaud API requires a batch_id to retrieve journal entries.
  The pipeline must first list all batch IDs then fetch entries per batch.
  This may produce multiple RAW tables (one per batch) or be consolidated
  into one table — confirm with Phinn after first pipeline run.

  Each journal entry row represents one debit or credit line.
*/

{{ config(materialized='view') }}

with source as (
    select _extracted_at, _record_id, _raw_data
    from {{ source('blackbaud', 'raw_blackbaud_nxt_journalentries') }}
),

renamed as (
    select
        _extracted_at,
        _raw_data:id::varchar                              as journal_entry_id,
        _raw_data:batch_id::varchar                        as batch_id,
        _raw_data:journal::varchar                         as journal_code,
        _raw_data:journal_description::varchar             as journal_description,
        _raw_data:date::date                               as journal_date,
        _raw_data:post_date::date                          as post_date,
        _raw_data:account_number::varchar                  as account_number,
        _raw_data:project::varchar                         as project_id,
        _raw_data:type_code::varchar                       as entry_type,
        _raw_data:amount::number(14,2)                     as amount,
        _raw_data:debit::number(14,2)                      as debit_amount,
        _raw_data:credit::number(14,2)                     as credit_amount,
        _raw_data:reference::varchar                       as reference,
        _raw_data:encumbrance_type::varchar                as encumbrance_type,
        _raw_data:create_date::timestamp_tz                as created_at,
        _raw_data:change_date::timestamp_tz                as updated_at,
        {{ generate_hashdiff(['_record_id', '_extracted_at::varchar']) }} as hashdiff
    from source
)

select * from renamed
