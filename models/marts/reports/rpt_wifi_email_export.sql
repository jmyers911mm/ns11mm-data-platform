-- Marts report: Blue State WiFi Email List Export [RESTRICTED / PII]
-- ---------------------------------------------------------------------------
-- Domain: marketing
-- Grain: one row per distinct email address per capture date
--
-- Governed replacement for report.blue_state_wifi_email_list_export. This is a
-- marketing email extract (WiFi captive-portal audience), NOT an analytics
-- mart -- it carries direct identifiers (email, name), so it is classified
-- RESTRICTED / PII per docs/architecture/DATA_CLASSIFICATION.md.
--
-- Governance (see DATA_CLASSIFICATION.md):
-- * the on-run-end masking hook (apply_masking_policies) applies column
-- masking to email_address / first_name / last_name on this view.
-- * least privilege: grants: {select: []} below OVERRIDES the marts-level
-- default grant, so POWERBI_ROLE / ML_ROLE do NOT receive this model.
-- Marketing-export access is granted outside dbt by the egress process.
-- * stays in the warehouse: the actual export to Blue State happens via a
-- governed, audited egress path -- not by copying this to a local file.
-- * Bronze immutable: source PII is never edited upstream.
--
-- Source is the WiFi audience feed (stub until ingested). Column classification
-- is declared in the accompanying schema.yml.

{{ config(
    materialized='view',
    tags=['pii', 'restricted', 'marketing_export'],
    grants={'select': []}
) }}

with audience as (
    select
        business_date                   as capture_date,
        email_address,
        coalesce(first_name, '')        as first_name,
        coalesce(last_name, '')         as last_name
    from {{ ref('stg_wifi__audience') }}
    -- Legacy Blue State export contract (t_bluestate_write_to_excel):
    -- accepted-AUP rows with non-null MAC / NAD / email.
    where aup_acceptance = 'Guest user has accepted the use policy'
      and mac_address is not null
      and nad_address is not null
      and email_address is not null
)

select distinct
    capture_date,
    email_address,
    first_name,
    last_name
from audience
