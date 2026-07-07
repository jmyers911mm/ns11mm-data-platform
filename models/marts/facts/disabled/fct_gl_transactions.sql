/*
  fct_gl_transactions
  Source: int_blackbaud + stg_blackbaud__accounts
  STATUS: Awaiting RAW data. New model — no POC equivalent.
*/

{{ config(enabled=false,materialized='table', cluster_by=['journal_date']) }}

select
    j.journal_entry_id,
    j.batch_id,
    j.journal_code,
    j.journal_description,
    j.journal_date,
    j.post_date,
    j.account_number,
    a.account_description,
    a.account_type,
    a.account_class,
    a.normal_balance,
    j.project_id,
    j.entry_type,
    j.amount,
    j.debit_amount,
    j.credit_amount,
    j.reference,
    j.posting_type,
    current_timestamp()                                     as _loaded_at
from {{ ref('int_blackbaud') }} j
left join {{ ref('stg_blackbaud__accounts') }} a on j.account_number = a.account_number
