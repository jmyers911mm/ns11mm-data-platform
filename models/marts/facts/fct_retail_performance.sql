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
-- Budget is left-joined from a stub seed (empty today) to preserve the seam
-- per ADR-005 (budget source gated).

{{ config(materialized='table') }}

with perf as (
    select * from {{ ref('int_retail__performance') }}
),

budget as (
    -- Real retail budget feed (fact_retail_forecasts): one row per facility/day
    -- with metric columns. revenue_budget -> net_sales seam, profit_budget ->
    -- net_profit seam. Already 1:1 at facility/day.
    select
        business_date                       as date_key,
        key_facility,
        revenue_budget                      as net_sales_budget,
        profit_budget                       as net_profit_budget
    from {{ ref('stg_budget__retail') }}
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

        -- Budget seam (null until staged)
        b.net_sales_budget,
        b.net_profit_budget

    from perf p
    inner join {{ ref('dim_date') }} dd on p.date_key = dd.date_key
    left join {{ ref('dim_facility') }} f on p.key_facility = f.key_facility
    left join budget b on p.date_key = b.date_key and p.key_facility = b.key_facility
)

select * from final
