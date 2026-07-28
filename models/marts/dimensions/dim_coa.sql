-- Marts dimension: dim_coa — Gateway chart of accounts for journal classification
-- Co-authored with CoCo
-- ---------------------------------------------------------------------------
-- Domain: admissions / ticketing (finance mapping)
-- Grain: one row per coa_id (chart of accounts entry)
--
-- Gateway chart of accounts dimension for journal entry classification.
--
-- Source: stg_gateway__coa

{{ config(materialized='table', tags=['daily', 'critical']) }}

with accounts as (
    select * from {{ ref('stg_gateway__coa') }}
)

select
    coa_id                              as coa_key,
    coa_id,
    account_id,
    gl_code,
    trim(account_name)                  as account_name,
    account_kind,
    category,
    subcategory,
    trim(code_description)              as code_description,
    company_id,
    rpt_action                          as report_action,
    case when is_active = 'Y' then true else false end as is_active,
    current_timestamp()                 as _loaded_at
from accounts
