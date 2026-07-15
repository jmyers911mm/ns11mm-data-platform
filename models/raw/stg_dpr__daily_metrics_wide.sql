-- Bronze staging: wide daily DPR metrics feed (misnamed source)
-- ---------------------------------------------------------------------------
-- Domain: DPR (cross-domain)
-- Grain:  one row per key_date
--
-- IMPORTANT: the uploaded seed_wifi_audience is NOT a WiFi email audience. It is
-- a WIDE daily DPR-metrics table (attendance, ticket/tour/donation measures,
-- retail profit, operating expenses, civic programs, ...) with a single
-- daily_wifi_visitors column. This staging exposes it faithfully; it does NOT
-- feed the governed PII email export (rpt_wifi_email_export still needs the real
-- stage_acceptance_uap_daily audience feed with email/name).
--
-- Useful now as an independent reconciliation/parity source against the built
-- DPR marts. ADR-001: rename/recast only. key_date YYYYMMDD; 'NULL' -> null.
{{ config(materialized='view') }}

with source as (
    select * from {{ source('report_estate_seed', 'seed_wifi_audience') }}
),
staged as (
    select
        try_to_date(key_date::varchar, 'YYYYMMDD')                       as business_date,
        mem_attendance::integer                                          as mem_attendance,
        mus_attendance::integer                                          as mus_attendance,
        try_to_decimal(nullif(tickets_sold::varchar,'NULL'),18,0)        as tickets_sold,
        try_to_decimal(nullif(tickets_issued::varchar,'NULL'),18,0)      as tickets_issued,
        try_to_decimal(nullif(ticket_revenue::varchar,'NULL'),18,2)      as ticket_revenue,
        try_to_decimal(nullif(pass_revenue::varchar,'NULL'),18,2)        as pass_revenue,
        try_to_decimal(nullif(mus_store_gross_profit::varchar,'NULL'),18,2) as mus_store_gross_profit,
        try_to_decimal(nullif(retail_carts_gross_profit::varchar,'NULL'),18,2) as retail_carts_gross_profit,
        try_to_decimal(nullif(total_donations::varchar,'NULL'),18,2)     as total_donations,
        try_to_decimal(nullif(civic_programs::varchar,'NULL'),18,2)      as civic_programs,
        daily_wifi_visitors::integer                                     as daily_wifi_visitors,
        _loaded_at
    from source
)
select * from staged
