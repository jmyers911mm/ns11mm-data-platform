-- Marts report: DPR retail conform — the retail sub-metrics the DPR MTD/YTD workbooks print
-- ---------------------------------------------------------------------------
-- Domain: DPR / retail (cross-domain)
-- Grain:  one row per report_date
--
-- The DPR MTD/YTD workbooks print retail detail the DPR fact does not carry:
-- Museum Store visitors / customers / average sale / capture / conversion,
-- Retail Carts customers / average sale, E-Commerce order count, and Museum
-- Cafe transaction count. Those live on FCT_RETAIL_DAILY, so this model is the
-- single cross-domain conform: one row per date with each selling area's
-- counts and sales pivoted out by facility_group (never by raw key_facility —
-- the conformed name comes from dim_facility).
--
-- This is the mirror image of rpt_retail_report_long reaching into
-- fct_daily_performance for museum attendance: the same cross-domain seam,
-- pointed the other way.
--
-- Non-additive ratios (capture rate, conversion rate, average sale) are NOT
-- computed here — consumers carry the numerator and denominator and divide at
-- their display grain, so an MTD or YTD average sale is a ratio-of-sums.
-- net_sales is carried alongside net_profit because the DPR Excel Data export
-- prints area REVENUE while the MTD/YTD reports print gross PROFIT.
--
-- NOTE: visitor_count and ecom_orders are Sensource / Shopify stubs (zero
-- until those feeds land), so the visitor-based ratios resolve NULL by design.
--
-- ADR-004: all business logic in dbt, never Power BI.

{{ config(materialized='view', grants={'select': ['POWERBI_ROLE']}) }}

with r as (
    select
        rd.date_value       as report_date,
        f.facility_group,
        rd.net_sales,
        rd.net_profit,
        rd.transactions,
        rd.visitor_count,
        rd.ecom_orders
    from {{ ref('fct_retail_daily') }} rd
    left join {{ ref('dim_facility') }} f on rd.key_facility = f.key_facility
)

select
    report_date,

    -- Museum Store
    sum(case when facility_group = 'museum_store'   then visitor_count else 0 end) as mus_store_visitors,
    sum(case when facility_group = 'museum_store'   then transactions  else 0 end) as mus_store_customers,
    sum(case when facility_group = 'museum_store'   then net_sales     else 0 end) as mus_store_net_sales,
    sum(case when facility_group = 'museum_store'   then net_profit    else 0 end) as mus_store_net_profit,

    -- Memorial Carts
    sum(case when facility_group = 'memorial_carts' then transactions  else 0 end) as carts_customers,
    sum(case when facility_group = 'memorial_carts' then net_sales     else 0 end) as carts_net_sales,
    sum(case when facility_group = 'memorial_carts' then net_profit    else 0 end) as carts_net_profit,

    -- E-commerce
    sum(case when facility_group = 'ecommerce'      then ecom_orders   else 0 end) as ecom_orders,
    sum(case when facility_group = 'ecommerce'      then net_sales     else 0 end) as ecom_net_sales,
    sum(case when facility_group = 'ecommerce'      then net_profit    else 0 end) as ecom_net_profit,

    -- Museum Cafe
    sum(case when facility_group = 'museum_cafe'    then transactions  else 0 end) as cafe_transactions,
    sum(case when facility_group = 'museum_cafe'    then net_sales     else 0 end) as cafe_net_sales,
    sum(case when facility_group = 'museum_cafe'    then net_profit    else 0 end) as cafe_net_profit

from r
group by 1
