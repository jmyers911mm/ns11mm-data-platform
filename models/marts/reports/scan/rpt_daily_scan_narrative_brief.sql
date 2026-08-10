-- Marts report: deterministic narrative brief — pre-computed Daily Scan facts for the AI_COMPLETE prompt
-- ---------------------------------------------------------------------------
-- Domain: attendance / scanning / AI narrative
-- Grain: one row per report_date
--
-- Sibling of rpt_dpr_narrative_brief, deliberately simpler: aggregates the
-- day x segment scan rows up to ONE per-day brief — yesterday's total tickets
-- sold vs the DSR forecast, passes scanned, scan utilization
-- (scanned / sold, ratio-of-sums), the biggest over- and under-forecast
-- segments, and the market-mix leaders (share of tickets sold). The LLM
-- narrates ONLY this brief — it does not analyze. Every sentence traces to a
-- field here.
--
-- ADR-004: all analysis logic lives in this model, not the prompt or Power BI.

{{ config(materialized='view') }}

with w as (
    select * from {{ ref('rpt_daily_scan_powerbi') }}
),

-- Report date: previous day (the Daily Scan covers yesterday's activity)
as_of as (
    select max(report_date) as report_date
    from w
    where report_date < current_date()
),

day_rows as (
    select w.*
    from w
    inner join as_of on w.report_date = as_of.report_date
),

totals as (
    select
        report_date,
        max(is_commemoration_day)   as is_commemoration_day,
        sum(tickets_sold)           as total_sold,
        sum(forecast_tickets_sold)  as total_forecast,
        sum(passes_scanned)         as total_scanned
    from day_rows
    group by 1
),

-- Per-segment variance vs forecast and share of the day's tickets sold
segments as (
    select
        segment_name,
        tickets_sold,
        forecast_tickets_sold,
        passes_scanned,
        tickets_sold - forecast_tickets_sold                                        as var_amount,
        div0(tickets_sold - forecast_tickets_sold, nullif(abs(forecast_tickets_sold), 0)) as var_pct,
        div0(tickets_sold, nullif((select total_sold from totals), 0))              as share_of_sold
    from day_rows
),

top_over_forecast as (
    select array_agg(object_construct('segment', segment_name, 'var_amount', var_amount, 'var_pct', round(var_pct, 4)))
           within group (order by var_amount desc) as arr
    from (select * from segments where forecast_tickets_sold is not null and var_amount > 0 order by var_amount desc limit 3)
),
top_under_forecast as (
    select array_agg(object_construct('segment', segment_name, 'var_amount', var_amount, 'var_pct', round(var_pct, 4)))
           within group (order by var_amount asc) as arr
    from (select * from segments where forecast_tickets_sold is not null and var_amount < 0 order by var_amount asc limit 3)
),
mix_leaders as (
    select array_agg(object_construct('segment', segment_name, 'tickets_sold', tickets_sold, 'share_of_sold', round(share_of_sold, 4)))
           within group (order by tickets_sold desc) as arr
    from (select * from segments where tickets_sold is not null order by tickets_sold desc nulls last limit 3)
),

brief as (
    select
        t.report_date,
        object_construct(
            'report_date', t.report_date::varchar,
            'is_commemoration_day', t.is_commemoration_day,

            'totals', object_construct(
                'tickets_sold', t.total_sold,
                'forecast_tickets_sold', t.total_forecast,
                'forecast_var_pct', round(div0(t.total_sold - t.total_forecast, nullif(abs(t.total_forecast), 0)), 4),
                'passes_scanned', t.total_scanned,
                'scan_utilization', round(div0(t.total_scanned, nullif(t.total_sold, 0)), 4)
            ),

            'top_over_forecast', tof.arr,
            'top_under_forecast', tuf.arr,
            'market_mix_leaders', ml.arr
        ) as brief_json
    from totals t
    cross join top_over_forecast tof
    cross join top_under_forecast tuf
    cross join mix_leaders ml
)

select report_date, brief_json from brief
