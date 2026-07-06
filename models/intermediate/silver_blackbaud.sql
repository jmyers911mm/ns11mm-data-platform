/*
  silver_blackbaud
  Source: stg_blackbaud__journal_entries
  STATUS: Awaiting RAW data. New model — no POC equivalent.
  NOTE: See pipeline notes on batch-by-batch extraction requirement.
*/

{{
    config(
        enabled=false,
        materialized='incremental',
        unique_key='journal_entry_id',
        incremental_strategy='merge',
        on_schema_change='append_new_columns',
        tags=['daily', 'non-critical']
    )
}}

select
    journal_entry_id,
    batch_id,
    journal_code,
    journal_description,
    journal_date,
    post_date,
    account_number,
    project_id,
    entry_type,
    amount,
    debit_amount,
    credit_amount,
    reference,
    encumbrance_type,
    case
        when encumbrance_type is null then 'Actual'
        else 'Encumbrance'
    end                                                     as posting_type,
    created_at,
    updated_at,
    hashdiff,
    _extracted_at
from {{ ref('stg_blackbaud__journal_entries') }}

{% if is_incremental() %}
where _extracted_at > (select max(_extracted_at) from {{ this }})
{% endif %}
