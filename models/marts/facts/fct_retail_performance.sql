{{ config(materialized='table') }}

-- Marts fact: retail performance (tidy, category grain)
-- ---------------------------------------------------------------------------
-- Domain: retail
-- Grain:  one row per date_key x key_facility x category_code
--
-- The additive backbone of the Retail Performance Report. Long/tidy layout:
-- one row per selling area per product category per day, so any category
-- (t-shirts, hats, MAG, food, ...) rolls up without a per-category column.
-- Enriched with dim_date and the facility-area label seed.
--
-- Replaces legacy 911dw.fact_retail. ADR-004: additive measures only; ratios
-- and per-cap metrics are computed in rpt_retail_performance.
-- Budget is left-joined from a stub seed (empty today) to preserve the seam
-- per ADR-005 (budget source gated).

with perf as (
    select * from {{ ref('int_retail__performance') }}
),

area as (
    select key_facility, area_name, area_group, is_selling
    from {{ ref('seed_facility_area') }}
),

budget as (
    -- Real retail budget feed (fact_retail_forecasts): one row per facility/day
    -- with metric columns. revenue_budget -> net_sales seam, profit_budget ->
    -- net_profit seam. Already 1:1 at facility/day.
    select
        business_date                       as key_date,
        key_facility,
        revenue_budget                      as net_sales_budget,
        profit_budget                       as net_profit_budget
    from {{ ref('stg_budget__retail') }}
),

final as (
    select
        dd.date_id                                          as date_key,
        p.key_date                                          as date_value,
        p.key_facility,
        coalesce(a.area_name, 'Unmapped ' || p.key_facility) as area_name,
        a.area_group,
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
    inner join {{ ref('dim_date') }} dd on p.key_date = dd.date_id
    left join area a on p.key_facility = a.key_facility
    left join budget b on p.key_date = b.key_date and p.key_facility = b.key_facility
)

select * from final
