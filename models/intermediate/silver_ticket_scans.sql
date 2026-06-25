/*
  silver_ticket_scans
  Source: stg_gateway__transactions
  STATUS: Awaiting RAW data.
  NOTE: Gate scan data may be in a separate Gateway table from transactions.
  Confirm with Kenny whether scans are in Transactions or a separate Scans table.
*/

{{
    config(
        materialized='incremental',
        unique_key='transaction_id',
        incremental_strategy='merge',
        on_schema_change='append_new_columns',
        cluster_by=['transaction_date', 'gate_id'],
        tags=['daily', 'critical']
    )
}}

select
    transaction_id                                          as scan_id,
    transaction_date                                        as scan_date,
    gate_id,
    'VALID'                                                 as scan_result,
    true                                                    as is_valid_scan,
    ticket_type_id                                          as ticket_type,
    quantity                                                as visitor_count,
    _extracted_at,
    hashdiff
from {{ ref('stg_gateway__transactions') }}
where gate_id is not null

{% if is_incremental() %}
and _extracted_at > (select max(_extracted_at) from {{ this }})
{% endif %}
