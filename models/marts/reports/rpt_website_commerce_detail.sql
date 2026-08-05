-- Marts report: Website Commerce donations detail (day x title serving shape)
-- ---------------------------------------------------------------------------
-- Domain: ecommerce / fundraising
-- Grain:  one row per report_date x title
--
-- Serves the "Donations By Date" sheet of the Website Commerce workbook:
-- date, product title, quantity, revenue. Companion to
-- rpt_website_commerce_daily (same source, same revenue_type rule — kept
-- verbatim-identical; single authored rule). Donation rows only, matching
-- the legacy sheet; the daily model carries the type-level totals.
-- Same one-time-feed seam as the daily model: rows are recurring-feed only
-- until the one-time website feed lands.
-- PII note: projects title/quantity/revenue aggregates only — no order_id,
-- no email — so no masking surface is created.
--
-- ADR-004: all business logic in dbt, never Power BI.

{{ config(materialized='view', grants={'select': ['POWERBI_ROLE']}) }}

with recurring as (
    select
        cast(created_at as date)                    as report_date,
        title,
        case
            when lower(coalesce(order_type, '')) like '%member%'
              or lower(coalesce(title, ''))      like '%member%' then 'Membership'
            when lower(coalesce(order_type, '')) like '%don%'
              or lower(coalesce(title, ''))      like '%don%'    then 'Donation'
            else coalesce(order_type, 'Other')
        end                                         as revenue_type,
        quantity,
        revenue
    from {{ ref('stg_ecommerce__website_recurring') }}
    where created_at is not null
)

select
    report_date,
    title,
    sum(quantity)       as quantity,
    sum(revenue)        as revenue
from recurring
where revenue_type = 'Donation'
group by 1, 2
