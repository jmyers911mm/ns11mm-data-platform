/*
  dim_budget_version — Vena plan version dimension.
  STATUS: Awaiting RAW.RAW_VENA_* to be populated.
  TODO: Update source ref once Vena pipeline is active and MODELS dict is populated.
*/

{{ config(materialized='table') }}

-- PLACEHOLDER: Replace with production source ref
-- Source: stg_vena__budget -> int_vena -> this model
select
    null::varchar as budget_version_id,
    null::varchar as version_name,
    'placeholder — awaiting Vena RAW connection' as status
where 1 = 0
