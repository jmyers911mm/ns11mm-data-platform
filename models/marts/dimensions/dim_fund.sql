/*
  dim_fund — Blackbaud Financial Edge fund and department dimension.
  STATUS: Awaiting RAW.RAW_BLACKBAUD_NXT_ACCOUNTS to be populated.
  TODO: Update source ref once Blackbaud pipeline is active.
*/

{{ config(materialized='table') }}

-- PLACEHOLDER: Replace with production source ref
-- Source: stg_blackbaud__accounts -> int_blackbaud -> this model
select
    null::varchar as fund_id,
    'placeholder — awaiting Blackbaud RAW connection' as status
where 1 = 0
