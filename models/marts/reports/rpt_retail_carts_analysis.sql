-- Marts report: Retail Carts Analysis Report
-- ---------------------------------------------------------------------------
-- Domain: retail
-- Grain: one row per date_key (Memorial Carts area)
--
-- Presentation view for report.retail_carts_analysis_report. A memorial-carts
-- lens on fct_retail_daily with the legacy "adjusted memorial visitor"
-- denominator: memorial visitors, less 25%, less museum visitors -- the plaza-
-- only foot traffic the carts actually convert. Capture rate, profit-per-cap
-- and sales-per-cap all divide by that adjusted denominator.
--
-- Facilities are referenced by their conformed area_name (carried on
-- fct_retail_daily from dim_facility) rather than raw key_facility numbers:
-- 'Memorial Carts' (was 1020) and 'Atrium' (was 1030, museum-visitor proxy).
--
-- NOTE: mem/mus visitor counts come from the Sensource stub (int_retail__
-- visitors) and are 0 until sensordata lands -- so the per-cap/capture ratios
-- are NULL by design today. The additive sales/profit/customers are live now.
-- ADR-004: no logic in Power BI; reads this view as-is.

{{ config(materialized='view') }}

with carts as (
    select
        date_key, date_value, is_commemoration_day,
        net_sales, net_profit, transactions
    from {{ ref('fct_retail_daily') }}
    where area_name = 'Memorial Carts'
),

visitors as (
    -- Facility-day visitor counts: Atrium proxies museum visitors;
    -- memorial visitors are the plaza count (stub until Sensource).
    select
        date_value,
        sum(case when area_name = 'Memorial Carts' then visitor_count else 0 end) as mem_visitors,
        sum(case when area_name = 'Atrium'         then visitor_count else 0 end) as mus_visitors
    from {{ ref('fct_retail_daily') }}
    group by 1
),

joined as (
    select
        c.date_key,
        c.date_value,
        c.is_commemoration_day,
        c.net_sales                                     as sales_mem_cart,
        c.net_profit                                    as profit_mem_cart,
        c.transactions                                  as mem_cart_customers,
        v.mem_visitors,
        v.mus_visitors,
        -- Adjusted denominator: plaza-only visitors the carts convert
        greatest((v.mem_visitors - 0.25 * v.mem_visitors) - v.mus_visitors, 0) as adj_visitors
    from carts c
    left join visitors v on c.date_value = v.date_value
)

select
    date_key,
    date_value,
    is_commemoration_day,
    sales_mem_cart,
    profit_mem_cart,
    mem_cart_customers,
    mem_visitors,
    mus_visitors,
    adj_visitors,
    -- Non-additive ratios at query grain
    profit_mem_cart / nullif(sales_mem_cart, 0)         as profit_margin,
    sales_mem_cart  / nullif(mem_cart_customers, 0)     as avg_sale,
    mem_cart_customers / nullif(adj_visitors, 0)        as capture_rate,
    profit_mem_cart / nullif(adj_visitors, 0)           as profit_per_cap,
    sales_mem_cart  / nullif(adj_visitors, 0)           as sales_per_cap
from joined
