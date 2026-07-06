/*
  silver_classy
  Source: stg_classy__transactions
  STATUS: Awaiting RAW data. New model — no POC equivalent.
*/

{{
    config(
        enabled=false,
        materialized='incremental',
        unique_key='transaction_id',
        incremental_strategy='merge',
        on_schema_change='append_new_columns',
        tags=['daily', 'critical']
    )
}}

select
    transaction_id,
    created_at::date                                        as transaction_date,
    campaign_id,
    donor_member_id,
    gross_amount,
    net_amount,
    processing_fee,
    donor_covered_fee,
    currency_code,
    donation_frequency,
    case donation_frequency
        when 'one-time'  then false
        when 'monthly'   then true
        when 'annually'  then true
        else false
    end                                                     as is_recurring,
    is_anonymous,
    payment_type,
    donor_comment,
    created_at,
    updated_at,
    hashdiff,
    _extracted_at
from {{ ref('stg_classy__transactions') }}

{% if is_incremental() %}
where _extracted_at > (select max(_extracted_at) from {{ this }})
{% endif %}
