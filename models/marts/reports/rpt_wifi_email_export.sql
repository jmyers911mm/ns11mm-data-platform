{{ config(
    materialized='view',
    tags=['pii', 'restricted', 'marketing_export']
) }}

-- Marts report: Blue State WiFi Email List Export  [RESTRICTED / PII]
-- ---------------------------------------------------------------------------
-- Domain: marketing
-- Grain:  one row per distinct email address per capture date
--
-- Governed replacement for report.blue_state_wifi_email_list_export. This is a
-- marketing email extract (WiFi captive-portal audience), NOT an analytics
-- mart -- it carries direct identifiers (email, name), so it is classified
-- RESTRICTED / PII per docs/architecture/DATA_CLASSIFICATION.md.
--
-- Governance (see DATA_CLASSIFICATION.md):
--   * tags pii/restricted -> the on-run-end masking hook applies column masking
--     policies to email_address / first_name / last_name automatically.
--   * least privilege: only marketing-export roles should be granted on this
--     model; POWERBI_ROLE / ML_ROLE must NOT receive it.
--   * stays in the warehouse: the actual export to Blue State happens via a
--     governed, audited egress path -- not by copying this to a local file.
--   * Bronze immutable: source PII is never edited upstream.
--
-- Source is the WiFi audience feed (stub until ingested). Column classification
-- is declared in the accompanying schema.yml.

with audience as (
    select
        cast(business_date as date)     as capture_date,
        lower(email_address)            as email_address,
        coalesce(first_name, '')        as first_name,
        coalesce(last_name, '')         as last_name
    from {{ ref('tmp_seed_wifi__audience') }}
    where email_address is not null
)

select distinct
    capture_date,
    email_address,
    first_name,
    last_name
from audience
