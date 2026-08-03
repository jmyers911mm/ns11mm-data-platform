-- Marts report: long category-grain serving shape for the Retail Performance Report (page 2)
-- ---------------------------------------------------------------------------
-- Domain: retail
-- Grain:  one row per report_date x key_facility x category_code
--
-- Category page of the Retail Performance Report: additive units / profit /
-- sales / donations per product category, projected from
-- fct_retail_performance. Feeds the Power BI Retail Performance Report
-- dataset (page 2), which shows Total Units + Total Profit per category
-- (Flown Flag, Water, T-shirt, Hoodie, Hats, Keychains, Magnets, Drinkware,
-- Totes, Rubber Bracelet, Food, Beverage, MAG, ...) with the same period
-- columns as page 1 — additive-only so DAX rolls up periods.
-- NOTE: budget is category-level NULL BY DESIGN (the retail forecast is
-- facility-grain; 7.9.0 removed the wrong-grain join that repeated the
-- facility budget on every category row). Goals come from
-- rpt_retail_budget_daily at facility grain; the seam here stays open for a
-- category-grain forecast if one ever lands.
--
-- ADR-004: all business logic in dbt, never Power BI.

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
