-- Marts report: Retail Performance Report
-- ---------------------------------------------------------------------------
-- Domain: retail
-- Grain: one row per date_key x key_facility (ratios), with a category
-- drill-down available from fct_retail_performance.
--
-- Presentation layer for the legacy Retail Performance Report
-- (report.911dw.dayofdata.arialnormal). Computes the report's non-additive
-- ratios at the query grain from fct_retail_daily -- never averaged across
-- days -- following the DPR rpt_ pattern:
-- ConversionRate = transactions / visitors
-- RevPerVis = net_sales / visitors
-- AvgSale = net_sales / transactions
-- DonPerVis = donations / visitors
-- ProfitMargin = net_profit / net_sales
--
-- Ratios divide by NULLIF(...,0). Visitor-based ratios are NULL until the
-- Sensource feed lands (visitor_count stub = 0). MTD/YTD roll-ups are computed
-- on demand here rather than materialized per period.
-- ADR-004: no business logic in Power BI; it reads this view as-is.

{{ config(materialized='view') }}

with daily as (
    select * from {{ ref('fct_retail_daily') }}
)

select
    date_key,
    date_value,
    key_facility,
    area_name,
    area_group,
    is_commemoration_day,

    -- Additive passthrough
    net_sales,
    net_profit,
    net_units,
    donations,
    transactions,
    visitor_count,
    ecom_orders,

    -- Non-additive ratios (ratio-of-sums at this grain)
    net_profit / nullif(net_sales, 0)                       as profit_margin,
    net_sales  / nullif(transactions, 0)                    as avg_sale,
    transactions / nullif(visitor_count, 0)                 as conversion_rate,
    net_sales  / nullif(visitor_count, 0)                   as rev_per_visitor,
    donations  / nullif(visitor_count, 0)                   as donations_per_visitor

from daily
