{{ config(materialized='view') }}

-- Marts report: Monthly Retail KPI
-- ---------------------------------------------------------------------------
-- Domain: retail
-- Grain:  one row per fiscal month x selling area
--
-- Monthly rollup of fct_retail_daily for report.monthly_retail_kpi (the legacy
-- report is a kettle-driven monthly matrix per area: sales, profit, units,
-- transactions, avg sale, conversion rate, rev-per-visitor, capture rate).
-- Ratios are recomputed at the month grain (ratio-of-sums), never averaged
-- from the daily grain. Visitor-based KPIs are NULL until Sensource lands.
-- ADR-004: no logic in Power BI.

with daily as (
    select * from {{ ref('fct_retail_daily') }}
),

dated as (
    select d.*, dd.fiscal_year, dd.fiscal_month, dd.month_name, dd.year_number, dd.month_of_year
    from daily d
    inner join {{ ref('dim_date') }} dd on d.date_key = dd.date_key
),

monthly as (
    select
        fiscal_year,
        fiscal_month,
        year_number      as calendar_year,
        month_of_year    as calendar_month,
        max(month_name)  as month_name,
        key_facility,
        max(area_name)   as area_name,
        max(area_group)  as area_group,

        sum(net_sales)     as net_sales,
        sum(net_profit)    as net_profit,
        sum(net_units)     as net_units,
        sum(donations)     as donations,
        sum(transactions)  as transactions,
        sum(visitor_count) as visitor_count
    from dated
    group by 1, 2, 3, 4, 6
)

select
    fiscal_year,
    fiscal_month,
    calendar_year,
    calendar_month,
    month_name,
    key_facility,
    area_name,
    area_group,
    net_sales,
    net_profit,
    net_units,
    donations,
    transactions,
    visitor_count,
    -- Month-grain ratios
    net_profit / nullif(net_sales, 0)       as profit_margin,
    net_sales  / nullif(transactions, 0)    as avg_sale,
    transactions / nullif(visitor_count, 0) as conversion_rate,
    net_sales  / nullif(visitor_count, 0)   as rev_per_visitor,
    net_units  / nullif(visitor_count, 0)   as units_per_visitor
from monthly