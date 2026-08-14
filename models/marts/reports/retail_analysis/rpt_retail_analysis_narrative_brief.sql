-- Marts report: deterministic narrative brief — pre-computed Retail Analysis facts for the AI_COMPLETE prompt
-- ---------------------------------------------------------------------------
-- Domain: retail / AI narrative
-- Grain: one row per report_date
--
-- Twin of rpt_retail_narrative_brief and rpt_carts_narrative_brief. Collapses
-- rpt_retail_analysis_report_long to ONE per-day brief: the printed headline
-- measures for all four selling blocks plus the two attendance denominators,
-- each with budget variance, day-over-day, same-weekday-last-week, YoY and
-- MTD/YTD context, a 7-day direction, and the top movers. The LLM narrates
-- ONLY this brief -- it does not analyze. Every sentence traces to a field here.
--
-- Reads the long serving shape rather than the fact so the narrative and the
-- Power BI matrix can never disagree about a number, and so the actual/budget
-- alignment is authored exactly once (rpt_retail_analysis_report_long).
--
-- RATIOS ARE DIVIDED HERE AND ONLY HERE. The brief is a display grain, so
-- ratio-of-sums is computed from the carried numerator/denominator pairs at
-- the day grain the note describes (ADR-021: divide once at display grain).
-- The five Stub lines (water x2, medallion x3) are deliberately excluded --
-- a brief that reported them would report typed NULLs as facts.
--
-- ADR-004: all analysis logic lives in this model, not the prompt or Power BI.

{{ config(materialized='view') }}

{#- Additive currency/count lines the movers rank over. -#}
{% set headline_lines = [
    ('ms_sales',             'Museum Store Sales'),
    ('ms_profit',            'Museum Store Profit'),
    ('ms_customers',         'Museum Store Customers'),
    ('ms_visitors',          'Museum Store Visitors'),
    ('vesey_profit',         'Vesey Profit'),
    ('vesey_customers',      'Vesey Customers'),
    ('ecom_profit',          'E-Commerce Gross Profit'),
    ('ecom_orders',          'E-Commerce Orders'),
    ('mem_cart_profit',      'Memorial Carts Profit'),
    ('mem_cart_customers',   'Memorial Carts Customers'),
    ('museum_attendance',    'Museum Attendance'),
    ('memorial_attendance',  'Memorial Attendance')
] %}

{#- Ratio lines: label -> numerator alias, denominator alias. -#}
{% set ratio_lines = [
    ('ms_capture_rate',      'Museum Store Capture Rate',    'ms_capture_num',    'ms_capture_den'),
    ('ms_conversion_rate',   'Museum Store Conversion Rate', 'ms_conversion_num', 'ms_conversion_den'),
    ('ms_avg_sale',          'Museum Store Average Sale',    'ms_avg_sale_num',   'ms_avg_sale_den'),
    ('mem_cart_capture_rate','Memorial Carts Capture Rate',  'mc_capture_num',    'mc_capture_den')
] %}

with long as (
    select * from {{ ref('rpt_retail_analysis_report_long') }}
),

-- Per-date pivot of the long shape. Conditional aggregation over a closed set
-- of line codes -- the codes live in the layout seed, this is the pivot.
agg as (
    select
        l.report_date,
        max(dd.is_commemoration_day)                                                           as is_commemoration_day,

        sum(case when l.line_item_code = 'MS__SALES'                   then l.amount end)      as ms_sales,
        sum(case when l.line_item_code = 'MS__PROFIT'                  then l.amount end)      as ms_profit,
        sum(case when l.line_item_code = 'MS__CUSTOMERS'               then l.amount end)      as ms_customers,
        sum(case when l.line_item_code = 'MS__VISITORS'                then l.amount end)      as ms_visitors,
        sum(case when l.line_item_code = 'VESEY__PROFIT'               then l.amount end)      as vesey_profit,
        sum(case when l.line_item_code = 'VESEY__CUSTOMERS'            then l.amount end)      as vesey_customers,
        sum(case when l.line_item_code = 'ECOM__PROFIT'                then l.amount end)      as ecom_profit,
        sum(case when l.line_item_code = 'ECOM__ORDERS'                then l.amount end)      as ecom_orders,
        sum(case when l.line_item_code = 'MEM_CART__PROFIT'            then l.amount end)      as mem_cart_profit,
        sum(case when l.line_item_code = 'MEM_CART__CUSTOMERS'         then l.amount end)      as mem_cart_customers,
        sum(case when l.line_item_code = 'MUSEUM_ATTENDANCE'           then l.amount end)      as museum_attendance,
        sum(case when l.line_item_code = 'MEM_CART__MEMORIAL_ATTENDANCE' then l.amount end)    as memorial_attendance,

        -- Ratio components, carried not divided
        sum(case when l.line_item_code = 'MS__CAPTURE_RATE'            then l.numerator end)   as ms_capture_num,
        sum(case when l.line_item_code = 'MS__CAPTURE_RATE'            then l.denominator end) as ms_capture_den,
        sum(case when l.line_item_code = 'MS__CONVERSION_RATE'         then l.numerator end)   as ms_conversion_num,
        sum(case when l.line_item_code = 'MS__CONVERSION_RATE'         then l.denominator end) as ms_conversion_den,
        sum(case when l.line_item_code = 'MS__AVG_SALE'                then l.numerator end)   as ms_avg_sale_num,
        sum(case when l.line_item_code = 'MS__AVG_SALE'                then l.denominator end) as ms_avg_sale_den,
        sum(case when l.line_item_code = 'MEM_CART__CAPTURE_RATE'      then l.numerator end)   as mc_capture_num,
        sum(case when l.line_item_code = 'MEM_CART__CAPTURE_RATE'      then l.denominator end) as mc_capture_den

    from long l
    left join {{ ref('dim_date') }} dd on l.report_date = dd.date_key
    group by l.report_date
),

bagg as (
    select
        l.report_date,
        sum(case when l.line_item_code = 'MS__SALES'                   then l.budget_amount end)      as ms_sales,
        sum(case when l.line_item_code = 'MS__PROFIT'                  then l.budget_amount end)      as ms_profit,
        sum(case when l.line_item_code = 'MS__CUSTOMERS'               then l.budget_amount end)      as ms_customers,
        sum(case when l.line_item_code = 'MS__VISITORS'                then l.budget_amount end)      as ms_visitors,
        sum(case when l.line_item_code = 'VESEY__PROFIT'               then l.budget_amount end)      as vesey_profit,
        sum(case when l.line_item_code = 'VESEY__CUSTOMERS'            then l.budget_amount end)      as vesey_customers,
        sum(case when l.line_item_code = 'ECOM__PROFIT'                then l.budget_amount end)      as ecom_profit,
        sum(case when l.line_item_code = 'ECOM__ORDERS'                then l.budget_amount end)      as ecom_orders,
        sum(case when l.line_item_code = 'MEM_CART__PROFIT'            then l.budget_amount end)      as mem_cart_profit,
        sum(case when l.line_item_code = 'MEM_CART__CUSTOMERS'         then l.budget_amount end)      as mem_cart_customers,
        sum(case when l.line_item_code = 'MUSEUM_ATTENDANCE'           then l.budget_amount end)      as museum_attendance,
        sum(case when l.line_item_code = 'MEM_CART__MEMORIAL_ATTENDANCE' then l.budget_amount end)    as memorial_attendance,
        sum(case when l.line_item_code = 'MS__CAPTURE_RATE'            then l.budget_numerator end)   as ms_capture_num,
        sum(case when l.line_item_code = 'MS__CAPTURE_RATE'            then l.budget_denominator end) as ms_capture_den,
        sum(case when l.line_item_code = 'MS__CONVERSION_RATE'         then l.budget_numerator end)   as ms_conversion_num,
        sum(case when l.line_item_code = 'MS__CONVERSION_RATE'         then l.budget_denominator end) as ms_conversion_den,
        sum(case when l.line_item_code = 'MS__AVG_SALE'                then l.budget_numerator end)   as ms_avg_sale_num,
        sum(case when l.line_item_code = 'MS__AVG_SALE'                then l.budget_denominator end) as ms_avg_sale_den,
        sum(case when l.line_item_code = 'MEM_CART__CAPTURE_RATE'      then l.budget_numerator end)   as mc_capture_num,
        sum(case when l.line_item_code = 'MEM_CART__CAPTURE_RATE'      then l.budget_denominator end) as mc_capture_den
    from long l
    group by l.report_date
),

as_of as (
    select max(report_date) as report_date
    from agg
    where report_date < current_date()
      and ms_sales is not null
),

today        as ( select a.* from agg  a inner join as_of on a.report_date = as_of.report_date ),
budget_today as ( select b.* from bagg b inner join as_of on b.report_date = as_of.report_date ),
prior_day    as ( select a.* from agg  a where a.report_date = (select max(report_date) from agg where report_date < (select report_date from as_of)) ),
prior_week   as ( select a.* from agg  a inner join as_of on a.report_date = dateadd('day',   -7, as_of.report_date) ),
prior_year   as ( select a.* from agg  a inner join as_of on a.report_date = dateadd('day', -364, as_of.report_date) ),

period_totals as (
    select
        sum(a.ms_sales)        as ms_sales_mtd,
        sum(a.ms_profit)       as ms_profit_mtd,
        sum(a.mem_cart_profit) as mem_cart_profit_mtd
    from agg a inner join as_of
        on year(a.report_date)  = year(as_of.report_date)
       and month(a.report_date) = month(as_of.report_date)
       and a.report_date       <= as_of.report_date
),
ytd_totals as (
    select
        sum(a.ms_sales)        as ms_sales_ytd,
        sum(a.ms_profit)       as ms_profit_ytd,
        sum(a.mem_cart_profit) as mem_cart_profit_ytd
    from agg a inner join as_of
        on year(a.report_date) = year(as_of.report_date)
       and a.report_date      <= as_of.report_date
),
budget_mtd as (
    select sum(b.ms_sales) as ms_sales_mtd, sum(b.ms_profit) as ms_profit_mtd
    from bagg b
    where b.report_date >= date_trunc('month', (select report_date from as_of))
      and b.report_date <= (select report_date from as_of)
),
budget_ytd as (
    select sum(b.ms_sales) as ms_sales_ytd, sum(b.ms_profit) as ms_profit_ytd
    from bagg b
    where b.report_date >= date_trunc('year', (select report_date from as_of))
      and b.report_date <= (select report_date from as_of)
),

trailing_7d as (
    select
        regr_slope(a.ms_sales,        datediff('day', a.report_date, (select report_date from as_of))) as ms_sales_slope,
        regr_slope(a.ms_profit,       datediff('day', a.report_date, (select report_date from as_of))) as ms_profit_slope,
        regr_slope(a.museum_attendance, datediff('day', a.report_date, (select report_date from as_of))) as attendance_slope
    from agg a
    where a.report_date between dateadd('day', -6, (select report_date from as_of))
                            and (select report_date from as_of)
),

line_items as (
    select
        line_item, line_label, actual_val, budget_val, prior_val,
        div0(actual_val - budget_val, nullif(abs(budget_val), 0)) as var_pct,
        actual_val - budget_val                                   as var_amount,
        div0(actual_val - prior_val,  nullif(abs(prior_val), 0))  as dod_pct,
        actual_val - prior_val                                    as dod_amount
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
    select array_agg(object_construct('line', line_label, 'var_pct', round(var_pct, 4), 'var_amount', round(var_amount, 2)))
           within group (order by abs(var_amount) desc) as arr
    from (select * from line_items where budget_val is not null order by abs(var_amount) desc limit 3)
),
top_dod_movers as (
    select array_agg(object_construct('line', line_label, 'dod_pct', round(dod_pct, 4), 'dod_amount', round(dod_amount, 2)))
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
                    'label',   '{{ label }}',
                    'actual',  t.{{ col }},
                    'budget',  bt.{{ col }},
                    'var_pct', round(div0(t.{{ col }} - bt.{{ col }}, nullif(abs(bt.{{ col }}), 0)), 4),
                    'dod_pct', round(div0(t.{{ col }} - p.{{ col }},  nullif(abs(p.{{ col }}),  0)), 4),
                    'wow_pct', round(div0(t.{{ col }} - w.{{ col }},  nullif(abs(w.{{ col }}),  0)), 4),
                    'yoy_pct', round(div0(t.{{ col }} - py.{{ col }}, nullif(abs(py.{{ col }}), 0)), 4)
                ){% if not loop.last %},{% endif %}
                {% endfor %}
            ),

            -- Ratio-of-sums from the carried components. This is the ONLY place
            -- the Retail Analysis ratios are divided.
            'ratios', object_construct(
                {% for col, label, num, den in ratio_lines %}
                '{{ col }}', object_construct(
                    'label',       '{{ label }}',
                    'numerator',   t.{{ num }},
                    'denominator', t.{{ den }},
                    'actual',      round(div0(t.{{ num }},  t.{{ den }}),  6),
                    'budget',      round(div0(bt.{{ num }}, bt.{{ den }}), 6),
                    'prior_year',  round(div0(py.{{ num }}, py.{{ den }}), 6)
                ){% if not loop.last %},{% endif %}
                {% endfor %}
            ),

            'period_context', object_construct(
                'ms_sales_mtd',           pt.ms_sales_mtd,
                'ms_sales_ytd',           yt.ms_sales_ytd,
                'budget_ms_sales_mtd',    bm.ms_sales_mtd,
                'budget_ms_sales_ytd',    by2.ms_sales_ytd,
                'ms_profit_mtd',          pt.ms_profit_mtd,
                'ms_profit_ytd',          yt.ms_profit_ytd,
                'mem_cart_profit_mtd',    pt.mem_cart_profit_mtd,
                'mem_cart_profit_ytd',    yt.mem_cart_profit_ytd
            ),

            'direction_7d', object_construct(
                'ms_sales',         case when tr.ms_sales_slope  > 0 then 'rising' when tr.ms_sales_slope  < 0 then 'falling' else 'flat' end,
                'ms_profit',        case when tr.ms_profit_slope > 0 then 'rising' when tr.ms_profit_slope < 0 then 'falling' else 'flat' end,
                'museum_attendance',case when tr.attendance_slope> 0 then 'rising' when tr.attendance_slope< 0 then 'falling' else 'flat' end
            ),

            'unavailable_lines', array_construct(
                'WATER__MUS_STORE', 'WATER__MEM_CART',
                'MEDALLION__SALES', 'MEDALLION__PROFIT', 'MEDALLION__UNITS_SOLD'
            ),

            'top_budget_movers', tbm.arr,
            'top_dod_movers',    tdm.arr
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
