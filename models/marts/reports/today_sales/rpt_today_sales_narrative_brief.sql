-- Marts report: deterministic narrative brief — pre-computed Today's Sales facts for the AI_COMPLETE prompt
-- ---------------------------------------------------------------------------
-- Domain: retail (intraday) / AI narrative
-- Grain: one row per report_date
--
-- Sibling of rpt_retail_narrative_brief, INTRADAY framing: the report date is
-- CURRENT_DATE (day-to-date, not yesterday), and the comparison baseline is
-- the same weekday last week's full-day total — so the deltas read "today so
-- far vs last <weekday>'s whole day". Deliberately simpler than the retail
-- brief: headline day-to-date totals, per-area splits, top hour, top area,
-- and vs-last-week deltas. No budget section — the report has no goals. The
-- LLM narrates ONLY this brief — it does not analyze. Every sentence traces
-- to a field here. Emits zero rows before the first same-day feed lands.
--
-- ADR-004: all analysis logic lives in this model, not the prompt or Power BI.

-- 8.1.0: tags=['intraday'] added so the 300-second intraday statement
-- timeout in dbt_project.yml actually applies to this model.
{{ config(materialized='view', tags=['intraday']) }}

with w as (
    select * from {{ ref('rpt_today_sales_powerbi') }}
),

-- Day-to-date totals for the current (intraday) date
today_agg as (
    select
        report_date,
        sum(sales)         as total_sales,
        sum(profit)        as total_profit,
        sum(units)         as total_units,
        sum(transactions)  as total_transactions
    from w
    where report_date = current_date()
    group by 1
),

-- Per-area day-to-date splits (area label from the wrapper's conformed area_name)
area_agg as (
    select
        area_name,
        sum(sales)        as sales,
        sum(profit)       as profit,
        sum(units)        as units,
        sum(transactions) as transactions
    from w
    where report_date = current_date()
    group by 1
),
area_arr as (
    select array_agg(object_construct(
        'area', area_name,
        'sales', round(sales, 2),
        'profit', round(profit, 2),
        'units', units,
        'transactions', transactions
    )) within group (order by sales desc nulls last) as arr
    from area_agg
),

-- Top hour and top area so far today (by sales)
top_hour as (
    select hour_of_day, sum(sales) as hour_sales
    from w
    where report_date = current_date()
    group by 1
    order by hour_sales desc nulls last
    limit 1
),
top_area as (
    select area_name, sales
    from area_agg
    order by sales desc nulls last
    limit 1
),

-- Baseline: same weekday last week, FULL-day total (day-to-date vs day-total
-- is intentional — flagged as such in the brief keys)
last_week as (
    select
        sum(sales)        as total_sales,
        sum(profit)       as total_profit,
        sum(units)        as total_units,
        sum(transactions) as total_transactions
    from w
    where report_date = dateadd('day', -7, current_date())
),

brief as (
    select
        t.report_date,
        object_construct(
            'report_date', t.report_date::varchar,
            'framing', 'intraday day-to-date vs same weekday last week full-day total',

            'day_to_date', object_construct(
                'total_sales', round(t.total_sales, 2),
                'total_profit', round(t.total_profit, 2),
                'total_units', t.total_units,
                'total_transactions', t.total_transactions
            ),

            'areas', aa.arr,

            'top_hour', object_construct(
                'hour_of_day', th.hour_of_day,
                'sales', round(th.hour_sales, 2)
            ),
            'top_area', object_construct(
                'area', ta.area_name,
                'sales', round(ta.sales, 2)
            ),

            'vs_last_week_day_total', object_construct(
                'lw_total_sales', round(lw.total_sales, 2),
                'lw_total_transactions', lw.total_transactions,
                'sales_delta', round(t.total_sales - lw.total_sales, 2),
                'sales_delta_pct', round(div0(t.total_sales - lw.total_sales, nullif(abs(lw.total_sales), 0)), 4),
                'transactions_delta', t.total_transactions - lw.total_transactions
            )
        ) as brief_json
    from today_agg t
    cross join area_arr aa
    left join top_hour th on true
    left join top_area ta on true
    cross join last_week lw
)

select report_date, brief_json from brief
