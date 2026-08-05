-- Marts report: deterministic narrative brief — pre-computed Carts Analysis facts for the AI_COMPLETE prompt
-- ---------------------------------------------------------------------------
-- Domain: retail / AI narrative
-- Grain: one row per report_date
--
-- Sibling of rpt_retail_narrative_brief for the Retail Carts Analysis
-- report. One JSON object per report_date with every fact the note may
-- reference: carts sales, gross profit, customers, average sale (components
-- carried, ratio pre-computed here deterministically for the prose),
-- day-over-day and same-weekday-last-week deltas, same-date-last-year
-- comparison, a trailing 7-day direction flag, and the commemoration guard.
-- Visitor-derived measures (capture rate, per-caps) are Sensource-stubbed
-- today, so they are deliberately NOT in the brief — the LLM cannot narrate
-- a stub. Add them here when sensordata lands. The LLM narrates ONLY this
-- brief — it does not analyze. Every sentence traces to a field here.
--
-- ADR-004: all analysis logic lives in this model, not the prompt or Power BI.

{{ config(materialized='view') }}

with c as (
    select
        date_value as report_date,
        is_commemoration_day,
        sales_mem_cart,
        profit_mem_cart,
        mem_cart_customers
    from {{ ref('rpt_retail_carts_analysis') }}
),

deltas as (
    select
        report_date,
        is_commemoration_day,
        sales_mem_cart,
        profit_mem_cart,
        mem_cart_customers,
        lag(sales_mem_cart, 1) over (order by report_date)       as sales_prior_day,
        lag(sales_mem_cart, 7) over (order by report_date)       as sales_last_week,
        lag(mem_cart_customers, 7) over (order by report_date)   as customers_last_week,
        avg(sales_mem_cart) over (
            order by report_date rows between 6 preceding and current row
        )                                                        as sales_avg_7d,
        avg(sales_mem_cart) over (
            order by report_date rows between 13 preceding and 7 preceding
        )                                                        as sales_avg_prior_7d
    from c
),

yoy as (
    select
        d.report_date,
        p.sales_mem_cart      as sales_last_year,
        p.mem_cart_customers  as customers_last_year
    from deltas d
    left join c p on p.report_date = dateadd('year', -1, d.report_date)
),

brief as (
    select
        d.report_date,
        object_construct(
            'report_date', d.report_date::varchar,
            'day_name', dayname(d.report_date),
            'is_commemoration_day', d.is_commemoration_day,
            'in_commemoration_window',
                (month(d.report_date) = 9 and day(d.report_date) between 6 and 16),

            'carts', object_construct(
                'sales', round(d.sales_mem_cart, 2),
                'gross_profit', round(d.profit_mem_cart, 2),
                'customers', d.mem_cart_customers,
                'avg_sale', round(div0(
                    d.sales_mem_cart, nullif(d.mem_cart_customers, 0)), 2)
            ),

            'vs_prior_day', object_construct(
                'sales_delta', round(d.sales_mem_cart - d.sales_prior_day, 2)
            ),

            'vs_same_weekday_last_week', object_construct(
                'sales_delta', round(d.sales_mem_cart - d.sales_last_week, 2),
                'sales_pct', round(div0(
                    d.sales_mem_cart - d.sales_last_week,
                    nullif(abs(d.sales_last_week), 0)), 4),
                'customers_delta', d.mem_cart_customers - d.customers_last_week
            ),

            'vs_same_date_last_year', object_construct(
                'sales_delta', round(d.sales_mem_cart - y.sales_last_year, 2),
                'sales_pct', round(div0(
                    d.sales_mem_cart - y.sales_last_year,
                    nullif(abs(y.sales_last_year), 0)), 4),
                'customers_delta', d.mem_cart_customers - y.customers_last_year
            ),

            'direction_7d', object_construct(
                'carts_sales', case
                    when d.sales_avg_prior_7d is null then 'insufficient_history'
                    when d.sales_avg_7d > d.sales_avg_prior_7d * 1.05 then 'rising'
                    when d.sales_avg_7d < d.sales_avg_prior_7d * 0.95 then 'falling'
                    else 'flat'
                end
            )
        ) as brief_json
    from deltas d
    left join yoy y on d.report_date = y.report_date
)

select report_date, brief_json from brief
