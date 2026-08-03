-- Marts fact: retail performance (tidy, category grain)
-- ---------------------------------------------------------------------------
-- Domain: retail
-- Grain: one row per date_key x key_facility x category_code
--
-- The additive backbone of the Retail Performance Report. Long/tidy layout:
-- one row per selling area per product category per day, so any category
-- (t-shirts, hats, MAG, food, ...) rolls up without a per-category column.
-- Enriched with dim_date and the conformed dim_facility area labels.
--
-- Replaces legacy 911dw.fact_retail. ADR-004: additive measures only; ratios
-- and per-cap metrics are computed in rpt_retail_performance.
-- BUDGET (7.9.0): the retail forecast is FACILITY-grain; repeating it on every
-- category row multiplied the budget under any category rollup. The category
-- seam is therefore NULL by design, and the single budget surface is the
-- fct_budget_retail_forecasts -> rpt_retail_budget_daily chain (one budget,
-- one chain). A category-grain forecast, if one ever lands, re-opens the seam.

{{ config(materialized='table') }}

with perf as (
    select * from {{ ref('int_retail__performance') }}
),

final as (
    select
        dd.date_key,
        p.date_key                                          as date_value,
        p.key_facility,
        coalesce(f.area_name, 'Unmapped ' || p.key_facility) as area_name,
        f.area_group,
        p.category_code,
        dd.is_commemoration_day,

        -- Additive measures
        p.net_sales,
        p.net_profit,
        p.net_units,
        p.cost_of_goods,
        p.donations,

        -- Budget seam: NULL BY DESIGN at category grain (see header). Goals
        -- live in rpt_retail_budget_daily (facility grain, one budget chain).
        cast(null as number(18, 4))                         as net_sales_budget,
        cast(null as number(18, 4))                         as net_profit_budget

    from perf p
    inner join {{ ref('dim_date') }} dd on p.date_key = dd.date_key
    left join {{ ref('dim_facility') }} f on p.key_facility = f.key_facility
)

select * from final
