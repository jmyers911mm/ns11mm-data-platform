-- Bronze staging: WiFi captive-portal audience  [RESTRICTED / PII]
-- ---------------------------------------------------------------------------
-- Domain: marketing
-- Grain:  one row per capture event (mac + logged_at); dedup to email/day downstream
-- Conforms seed_wifi_audience_real (911dw.stage_acceptance_uap_daily, loaded
-- from the SFTP CSV feed). Direct identifiers (email, name) + device ids
-- (MAC/IP/NAD) -- RESTRICTED per DATA_CLASSIFICATION.md. Mark PII in schema.yml,
-- keep least-privilege. ADR-001: rename/recast only.
-- Notes: key_date is YYYY-MM-DD (not YYYYMMDD like the other feeds); name fields
-- carry literal 'NULL' strings -> nullified.
{{ config(
    materialized='view',
    tags=['pii', 'restricted']
) }}

with source as (
    select * from {{ source('report_estate_seed', 'seed_stage_acceptance_uap_daily') }}
),
staged as (
    select
        try_to_date(key_date::varchar)              as business_date,   -- YYYY-MM-DD
        try_to_timestamp(logged_at::varchar)        as logged_at,
        aup_acceptance::varchar                     as aup_acceptance,
        lower(email_address)::varchar               as email_address,   -- PII
        nullif(first_name::varchar, 'NULL')         as first_name,      -- PII
        nullif(last_name::varchar, 'NULL')          as last_name,       -- PII
        mac_address::varchar                        as mac_address,     -- device id
        nad_address::varchar                        as nad_address,     -- device id
        ip_address::varchar                         as ip_address,      -- device id
        _loaded_at
    from source
)
select * from staged
