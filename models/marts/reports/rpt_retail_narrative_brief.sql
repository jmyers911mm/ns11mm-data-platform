-- Deterministic narrative brief: pre-computed Retail facts for the AI_COMPLETE prompt
-- ---------------------------------------------------------------------------
-- Domain: retail / AI narrative
-- Grain: one row per report_date
--
-- Twin of rpt_dpr_narrative_brief. Aggregates the day x facility actuals and
-- goals up to ONE per-day retail brief: headline totals + per-area splits,
-- day-over-day, same-day-prior-week, YoY, MTD/YTD, 7-day direction, and the
-- top movers by budget variance and DoD swing. The LLM narrates ONLY this
-- brief -- it does not analyze. Every sentence traces to a field here.
--
-- ADR-004: all analysis logic lives in this model, not the prompt or Power BI.

{{ config(materialized='view') }}

{% set headline_lines = [
    ('total_gms_sales',        'Total Gross Merchandise Sales'),
    ('total_gm_profit',        'Total Gross Margin Profit'),
    ('museum_store_sales',     'Museum Store Sales'),
    ('memorial_carts_sales',   'Memorial Carts Sales'),
    ('museum_cafe_sales',      'Museum Cafe Sales'),
    ('ecommerce_gross_profit', 'E-Commerce Gross Profit'),
    ('total_donations',        'Total Donation Ask'),
    ('museum_attendance',      'Museum Attendance')
] %}

with
-- Per-date attendance actual (cross-domain)
att as (
    select cast(date_key as date) as report_date, sum(mus_attendance) as museum_attendance
    from {{ ref('fct_daily_performance') }}
    group by 1
),

-- Per-date aggregate of the day x facility ACTUALS
agg as (
    select
        w.report_date,
        max(w.is_commemoration_day)                                                as is_commemoration_day,
        sum(w.net_sales)                                                           as total_gms_sales,
        sum(w.net_profit)                                                          as total_gm_profit,
        sum(w.donations)                                                           as total_donations,
        sum(case when w.key_facility = 1003 then w.net_sales  end)                 as museum_store_sales,
        sum(case when w.key_facility = 1020 then w.net_sales  end)                 as memorial_carts_sales,
        sum(case when w.key_facility = 4007 then w.net_sales  end)                 as museum_cafe_sales,
        sum(case when w.key_facility = 1234 then w.net_profit end)                 as ecommerce_gross_profit,
        att.museum_attendance                                                      as museum_attendance
    from {{ ref('rpt_retail_powerbi') }} w
    left join att on w.report_date = att.report_date
    group by w.report_date, att.museum_attendance
),

-- Per-date aggregate of the day x facility BUDGET (goal)
bagg as (
    select
        b.report_date,
        sum(b.net_sales)                                                           as total_gms_sales,
        sum(b.net_profit)                                                          as total_gm_profit,
        sum(b.donations)                                                           as total_donations,
        sum(case when b.key_facility = 1003 then b.net_sales  end)                 as museum_store_sales,
        sum(case when b.key_facility = 1020 then b.net_sales  end)                 as memorial_carts_sales,
        sum(case when b.key_facility = 4007 then b.net_sales  end)                 as museum_cafe_sales,
        sum(case when b.key_facility = 1234 then b.net_profit end)                 as ecommerce_gross_profit,
        max(b.museum_attendance)                                                   as museum_attendance
    from {{ ref('rpt_retail_budget_daily') }} b
    group by b.report_date
),

as_of as (
    select max(report_date) as report_date from agg where report_date < current_date()
),

today       as ( select a.* from agg  a inner join as_of on a.report_date = as_of.report_date ),
budget_today as ( select b.* from bagg b inner join as_of on b.report_date = as_of.report_date ),
prior_day   as ( select a.* from agg a where a.report_date = (select max(report_date) from agg where report_date < (select report_date from as_of)) ),
prior_week  as ( select a.* from agg a inner join as_of on a.report_date = dateadd('day',  -7, as_of.report_date) ),
prior_year  as ( select a.* from agg a inner join as_of on a.report_date = dateadd('day', -364, as_of.report_date) ),

period_totals as (
    select
        sum(total_gms_sales) as gms_sales_mtd,
        sum(total_gm_profit) as gm_profit_mtd
    from agg a inner join as_of
        on year(a.report_date) = year(as_of.report_date)
       and month(a.report_date) = month(as_of.report_date)
       and a.report_date <= as_of.report_date
),
ytd_totals as (
    select
        sum(total_gms_sales) as gms_sales_ytd,
        sum(total_gm_profit) as gm_profit_ytd
    from agg a inner join as_of
        on year(a.report_date) = year(as_of.report_date)
       and a.report_date <= as_of.report_date
),
budget_mtd as (
    select sum(total_gms_sales) as gms_sales_mtd
    from bagg b
    where b.report_date >= date_trunc('month', (select report_date from as_of))
      and b.report_date <= (select report_date from as_of)
),
budget_ytd as (
    select sum(total_gms_sales) as gms_sales_ytd
    from bagg b
    where b.report_date >= date_trunc('year', (select report_date from as_of))
      and b.report_date <= (select report_date from as_of)
),

trailing_7d as (
    select
        regr_slope(total_gms_sales, datediff('day', report_date, (select report_date from as_of))) as sales_slope,
        regr_slope(total_gm_profit, datediff('day', report_date, (select report_date from as_of))) as profit_slope
    from agg a
    where a.report_date between dateadd('day', -6, (select report_date from as_of))
                            and (select report_date from as_of)
),

-- Movers across the headline lines
line_items as (
    select line_item, line_label, actual_val, budget_val, prior_val,
           div0(actual_val - budget_val, nullif(abs(budget_val), 0)) as var_pct,
           actual_val - budget_val                                    as var_amount,
           div0(actual_val - prior_val, nullif(abs(prior_val), 0))   as dod_pct,
           actual_val - prior_val                                     as dod_amount
    from (
        {% for col, label in headline_lines %}
        select '{{ col }}' as line_item, '{{ label }}' as line_label,
               t.{{ col }} as actual_val, bt.{{ col }} as budget_val, p.{{ col }} as prior_val
        from today t cross join budget_today bt cross join prior_day p
        {% if not loop.last %}union all{% endif %}
        {% endfor %}
    )
    where actual_val is not null and actual_val != 0
),
top_budget_movers as (
    select array_agg(object_construct('line', line_label, 'var_pct', round(var_pct,4), 'var_amount', round(var_amount,2)))
           within group (order by abs(var_amount) desc) as arr
    from (select * from line_items where budget_val is not null order by abs(var_amount) desc limit 3)
),
top_dod_movers as (
    select array_agg(object_construct('line', line_label, 'dod_pct', round(dod_pct,4), 'dod_amount', round(dod_amount,2)))
           within group (order by abs(dod_amount) desc) as arr
    from (select * from line_items where prior_val is not null order by abs(dod_amount) desc limit 3)
),

brief as (
    select
        t.report_date,
        object_construct(
            'report_date', t.report_date::varchar,
            'is_commemoration_day', t.is_commemoration_day,
            'in_commemoration_window', (t.report_date between
                date_from_parts(year(t.report_date), 9, 6) and
                date_from_parts(year(t.report_date), 9, 16)),

            'metrics', object_construct(
                {% for col, label in headline_lines %}
                '{{ col }}', object_construct(
                    'label', '{{ label }}',
                    'actual', t.{{ col }},
                    'budget', bt.{{ col }},
                    'var_pct', round(div0(t.{{ col }} - bt.{{ col }}, nullif(abs(bt.{{ col }}), 0)), 4),
                    'dod_pct', round(div0(t.{{ col }} - p.{{ col }}, nullif(abs(p.{{ col }}), 0)), 4),
                    'wow_pct', round(div0(t.{{ col }} - w.{{ col }}, nullif(abs(w.{{ col }}), 0)), 4),
                    'yoy_pct', round(div0(t.{{ col }} - py.{{ col }}, nullif(abs(py.{{ col }}), 0)), 4)
                ){% if not loop.last %},{% endif %}
                {% endfor %}
            ),

            'period_context', object_construct(
                'gms_sales_mtd', pt.gms_sales_mtd,
                'gms_sales_ytd', yt.gms_sales_ytd,
                'budget_gms_sales_mtd', bm.gms_sales_mtd,
                'budget_gms_sales_ytd', by2.gms_sales_ytd,
                'gm_profit_mtd', pt.gm_profit_mtd,
                'gm_profit_ytd', yt.gm_profit_ytd
            ),

            'direction_7d', object_construct(
                'gms_sales', case when tr.sales_slope > 0 then 'rising' when tr.sales_slope < 0 then 'falling' else 'flat' end,
                'gm_profit', case when tr.profit_slope > 0 then 'rising' when tr.profit_slope < 0 then 'falling' else 'flat' end
            ),

            'top_budget_movers', tbm.arr,
            'top_dod_movers', tdm.arr
        ) as brief_json
    from today t
    cross join budget_today bt
    cross join prior_day p
    left join prior_week w on true
    left join prior_year py on true
    cross join period_totals pt
    cross join ytd_totals yt
    cross join budget_mtd bm
    cross join budget_ytd by2
    cross join trailing_7d tr
    cross join top_budget_movers tbm
    cross join top_dod_movers tdm
)

select report_date, brief_json from brief
