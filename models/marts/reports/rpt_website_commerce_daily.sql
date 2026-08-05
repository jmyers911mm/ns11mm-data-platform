-- Marts report: Website Commerce daily serving shape (day-grain revenue by type)
-- ---------------------------------------------------------------------------
-- Domain: ecommerce / fundraising
-- Grain:  one row per report_date x revenue_type
--
-- Day-grain Website Commerce presentation for Power BI, superseding the
-- month-pivot rpt_website_commerce for the Power BI rebuild (the legacy
-- month x year pivot becomes a Power BI matrix over dim_date — periods in
-- DAX, never materialized in SQL, per the report-family pattern). Covers
-- both workbook variants from one model:
--   - "By Month" / "By Date" sheets: sum(amount) sliced by dim_date
--   - "Recurring" variant: today ALL rows are is_recurring = true, because
--     the only live feed (stg_ecommerce__website_recurring) is the recurring
--     Drupal-commerce extract. One-time website revenue is an OPEN SEAM:
--     when the one-time feed lands, add its leg with is_recurring = false
--     and both variants light up correctly with no Power BI change.
-- revenue_type derivation (Donation / Membership / Other) reuses the ruled
-- open-set name matching from rpt_website_commerce verbatim — single
-- authored rule, do not fork it.
-- PII note: the staging source carries email; this model projects only
-- aggregates (no order_id, no email) so no masking surface is created.
--
-- ADR-004: all business logic in dbt, never Power BI.

{{ config(materialized='view', grants={'select': ['POWERBI_ROLE']}) }}

with recurring as (
    select
        cast(created_at as date)                    as report_date,
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
    revenue_type,
    true                as is_recurring,   -- only the recurring feed is live; see header
    sum(quantity)       as quantity,
    sum(revenue)        as revenue
from recurring
group by 1, 2
