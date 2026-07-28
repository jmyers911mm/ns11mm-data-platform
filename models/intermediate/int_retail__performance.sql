-- Silver intermediate: retail performance, tidy category grain
-- Co-authored with CoCo
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

        -- Non-donation retail measures
        sum(case when not is_donation then sale_amount - return_amount else 0 end)             as net_sales,
        sum(case when not is_donation then sale_amount - return_amount - sale_cost else 0 end) as net_profit,
        sum(case when not is_donation then sale_quantity - return_quantity else 0 end)         as net_units,
        sum(case when not is_donation then sale_cost else 0 end)                               as cost_of_goods,

        -- Donation measures; legacy nets sale + return
        sum(case when is_donation then sale_amount + return_amount else 0 end)                 as donations

    from lines
    group by 1, 2, 3
)

select * from aggregated
