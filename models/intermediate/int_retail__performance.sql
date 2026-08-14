-- Silver intermediate: retail performance, tidy category grain
-- ---------------------------------------------------------------------------
-- Domain: retail
-- Grain: one row per business_date x key_facility x category_code
--
-- Replaces the legacy 911dw.fact_retail category rollup (built by t_fact_retail
-- from ps_tkt_hist_lin). Aggregates the conformed CounterPoint retail lines into
-- additive sales / profit / unit / donation measures per selling area and
-- product category, so the Retail Performance Report's per-category breakdown
-- (t-shirts, hats, MAG, food, ...) is one tidy model instead of ~22 columns.
--
-- 8.3.0: cost_of_goods and net_profit now read `net_cost`, the centralized
-- netted cost from int_counterpoint__retail_lines, instead of `sale_cost`.
-- Legacy t_fact_cogs sums EXT_COST over sale AND return lines; taking the sale
-- side only gave a return its revenue back while keeping its cost, overstating
-- gross profit on every day with a return. sale_cost / return_cost remain
-- available as components -- do NOT re-derive netting from them.
--
-- ADR-001: reads only from int_ (staging is upstream).
-- ADR-004: all business logic here, not in Power BI.
-- Additive measures only; ratios (conversion, rev-per-vis, avg-sale) are
-- computed at query grain in rpt_retail_performance.
-- Donation split uses the is_donation flag derived once in retail_lines, not
-- the raw summary_category = 6 literal.

{{ config(materialized='view') }}

with lines as (
    select * from {{ ref('int_counterpoint__retail_lines') }}
),

aggregated as (
    select
        cast(business_date as date)                                 as date_key,
        key_facility,
        category_code,

        -- Non-donation retail measures. Netting comes from the centralized
        -- net_amount / net_quantity / net_cost columns (7.9.0 fix: this model
        -- previously netted with sale - return while every other consumer and
        -- the legacy-reconciled DPR chain net with sale + return, overstating
        -- net_sales/net_profit by 2x returns whenever a return occurred;
        -- 8.3.0 fix: cost was not netted at all).
        sum(case when not is_donation then net_amount else 0 end)              as net_sales,
        sum(case when not is_donation then net_amount - net_cost else 0 end)   as net_profit,
        sum(case when not is_donation then net_quantity else 0 end)            as net_units,
        sum(case when not is_donation then net_cost else 0 end)                as cost_of_goods,

        -- Donation measures; legacy nets sale + return (same centralized net)
        sum(case when is_donation then net_amount else 0 end)                  as donations

    from lines
    group by 1, 2, 3
)

select * from aggregated
