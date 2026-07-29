-- models/marts/reports/rpt_retail_category_long.sql
-- Category page of the Retail Performance Report (page 2): one row per
-- (report_date, key_facility, category_code) with additive units / profit /
-- sales / donations. Power BI shows Total Units + Total Profit per category
-- (Flown Flag, Water, T-shirt, Hoodie, Hats, Keychains, Magnets, Drinkware,
-- Totes, Rubber Bracelet, Food, Beverage, MAG, ...) with the same period
-- columns as page 1, so this stays additive and lets DAX roll up periods.
--
-- Additive-only (ADR-004). Budget is category-level NULL today (the retail
-- forecast is facility-grain, not category-grain); the seam is left open.

{{ config(materialized='view', grants={'select': ['POWERBI_ROLE']}) }}

select
    date_value                          as report_date,
    key_facility,
    area_name,
    area_group,
    category_code,
    is_commemoration_day,

    cast(net_units  as number(38,4))    as net_units,
    cast(net_profit as number(38,4))    as net_profit,
    cast(net_sales  as number(38,4))    as net_sales,
    cast(donations  as number(38,4))    as donations,

    -- Budget seams (facility-grain forecast has no category split yet)
    cast(net_sales_budget  as number(38,4)) as net_sales_budget,
    cast(net_profit_budget as number(38,4)) as net_profit_budget

from {{ ref('fct_retail_performance') }}
