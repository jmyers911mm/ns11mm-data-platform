-- Marts report: Website Commerce Report
-- ---------------------------------------------------------------------------
-- Domain: ecommerce / fundraising
-- Grain: one row per month x revenue_type x revenue_year
--
-- Presentation view for report.website_commerce_report -- recurring online
-- donation and membership revenue by month, pivoted by year. Now sourced from
-- the real recurring feed (stg_ecommerce__website_recurring) instead of the
-- stub. revenue_type is derived from order_type (Donation vs Membership);
-- revenue_year and month come from the created date. ADR-004: no logic in PBI.

{{ config(materialized='view') }}

with recurring as (
    select
        cast(created_at as date)                    as date_key,
        case
            when lower(coalesce(order_type,'')) like '%member%'
              or lower(coalesce(title,''))      like '%member%' then 'Membership'
            when lower(coalesce(order_type,'')) like '%don%'
              or lower(coalesce(title,''))      like '%don%'    then 'Donation'
            else coalesce(order_type, 'Other')
        end                                         as revenue_type,
        revenue
    from {{ ref('stg_ecommerce__website_recurring') }}
    where created_at is not null
),

dated as (
    select
        r.revenue_type,
        r.revenue,
        dd.year_number    as revenue_year,
        dd.month_of_year,
        dd.month_name
    from recurring r
    inner join {{ ref('dim_date') }} dd on r.date_key = dd.date_key
)

select
    month_of_year,
    max(month_name)     as month_name,
    revenue_type,
    revenue_year,
    sum(revenue)        as amount
from dated
group by 1, 3, 4
