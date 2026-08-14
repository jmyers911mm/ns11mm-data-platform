-- Marts report: deterministic narrative brief — pre-computed Earned Income Variance facts for the AI_COMPLETE prompt
-- ---------------------------------------------------------------------------
-- Domain: earned income / AI narrative
-- Grain: one row per report_date
--
-- Twin of rpt_dpr_narrative_brief and rpt_retail_analysis_narrative_brief.
-- Collapses rpt_earned_income_variance_report_long to ONE per-day brief: every
-- printed line with its budget variance, day-over-day, same-weekday-last-week,
-- year-over-year and MTD/YTD context, a 7-day direction, the top movers, and the
-- one printed ratio as a ratio-of-sums from its carried components. The LLM
-- narrates ONLY this brief -- it does not analyze. Every sentence traces to a
-- field here.
--
-- Reads the long serving shape rather than the fact so the note and the Power BI
-- matrix can never disagree about a number, and so the actual/budget alignment
-- is authored exactly once (rpt_earned_income_variance_budget_daily).
--
-- VARIANCE IS COMPUTED HERE, AT THE GRAIN THE NOTE DESCRIBES. var_amount is
-- actual minus budget and var_pct is that difference over budget, evaluated at
-- the day and at MTD/YTD from summed components -- never from a stored daily
-- difference. This is the display grain the ADR-021 ratio rule points at.
--
-- RATIOS ARE DIVIDED HERE AND ONLY HERE. average ticket price is
-- ticket_revenue over tickets, taken as a ratio of sums.
--
-- The two Stub lines (estimated and total operating expenses) are deliberately
-- excluded from `metrics` and named in `unavailable_lines`: a brief that
-- reported them would report typed NULLs as facts, and this report goes to the
-- CFO. See DECISION_MEMO.md.
--
-- ADR-004: all analysis logic lives in this model, not the prompt or Power BI.

{{ config(materialized='view') }}

{#- Additive printed lines the movers rank over. Stub lines excluded. -#}
{% set headline_lines = [
    ('museum_attendance',        'MUSEUM_ATTENDANCE',        'Museum Attendance'),
    ('tickets',                  'TICKETS',                  'Tickets'),
    ('ticket_revenue',           'TICKET_REVENUE',           'Ticket Revenue'),
    ('service_fees',             'SERVICE_FEES',             'Service Fees'),
    ('citypass_tickets',         'CITYPASS_TICKETS',         'CityPASS Tickets'),
    ('citypass_revenue',         'CITYPASS_REVENUE',         'CityPASS Revenue'),
    ('total_tickets_sold',       'TOTAL_TICKETS_SOLD',       'Total Tickets Sold'),
    ('total_admissions_revenue', 'TOTAL_ADMISSIONS_REVENUE', 'Total Admissions Revenue'),
    ('mus_guided_tours',         'MUS_GUIDED_TOURS',         'Museum Guided Tours'),
    ('mus_guided_tour_revenue',  'MUS_GUIDED_TOUR_REVENUE',  'Museum Guided Tour Revenue'),
    ('mem_guided_tours',         'MEM_GUIDED_TOURS',         'Memorial Guided Tours'),
    ('mem_guided_tour_revenue',  'MEM_GUIDED_TOUR_REVENUE',  'Memorial Guided Tour Revenue'),
    ('early_access_tours',       'EARLY_ACCESS_TOURS',       'Early Access Tours'),
    ('early_access_tour_revenue','EARLY_ACCESS_TOUR_REVENUE','Early Access Tour Revenue'),
    ('youth_fam_tours',          'YOUTH_FAM_TOURS',          'Youth and Family Tours'),
    ('youth_fam_tour_revenue',   'YOUTH_FAM_TOUR_REVENUE',   'Youth and Family Tour Revenue'),
    ('mem_mus_tours',            'MEM_MUS_TOURS',            'Memorial and Museum Tours'),
    ('mem_mus_tour_revenue',     'MEM_MUS_TOUR_REVENUE',     'Memorial and Museum Tour Revenue')
] %}

{#- Ratio lines: alias -> line code, label, numerator alias, denominator alias. -#}
{% set ratio_lines = [
    ('avg_ticket_price', 'AVG_TICKET_PRICE', 'Average Ticket Price', 'atp_num', 'atp_den')
] %}

with long as (
    select * from {{ ref('rpt_earned_income_variance_report_long') }}
),

-- Per-date pivot of the long shape. Conditional aggregation over a closed set of
-- line codes -- the codes live in the layout seed, this is the pivot.
agg as (
    select
        l.report_date,
        max(dd.is_commemoration_day)                                                        as is_commemoration_day,
        {% for alias, code, label in headline_lines %}
        sum(case when l.line_item_code = '{{ code }}' then l.amount end)                    as {{ alias }},
        {% endfor %}
        {% for alias, code, label, num, den in ratio_lines %}
        sum(case when l.line_item_code = '{{ code }}' then l.numerator end)                 as {{ num }},
        sum(case when l.line_item_code = '{{ code }}' then l.denominator end)               as {{ den }}{% if not loop.last %},{% endif %}
        {% endfor %}
    from long l
    left join {{ ref('dim_date') }} dd on l.report_date = dd.date_key
    group by l.report_date
),

bagg as (
    select
        l.report_date,
        {% for alias, code, label in headline_lines %}
        sum(case when l.line_item_code = '{{ code }}' then l.budget_amount end)             as {{ alias }},
        {% endfor %}
        {% for alias, code, label, num, den in ratio_lines %}
        sum(case when l.line_item_code = '{{ code }}' then l.budget_numerator end)          as {{ num }},
        sum(case when l.line_item_code = '{{ code }}' then l.budget_denominator end)        as {{ den }}{% if not loop.last %},{% endif %}
        {% endfor %}
    from long l
    group by l.report_date
),

as_of as (
    select max(report_date) as report_date
    from agg
    where report_date < current_date()
      and total_admissions_revenue is not null
),

today        as ( select a.* from agg  a inner join as_of on a.report_date = as_of.report_date ),
budget_today as ( select b.* from bagg b inner join as_of on b.report_date = as_of.report_date ),
prior_day    as ( select a.* from agg  a where a.report_date = (select max(report_date) from agg where report_date < (select report_date from as_of)) ),
prior_week   as ( select a.* from agg  a inner join as_of on a.report_date = dateadd('day',   -7, as_of.report_date) ),
prior_year   as ( select a.* from agg  a inner join as_of on a.report_date = dateadd('day', -364, as_of.report_date) ),

-- Period context. MTD/YTD variance is computed from SUMMED actuals and SUMMED
-- budgets, never from summed daily differences.
period_totals as (
    select
        sum(a.total_admissions_revenue)                                                     as total_admissions_revenue_mtd,
        sum(a.ticket_revenue)                                                               as ticket_revenue_mtd,
        sum(a.total_tickets_sold)                                                           as total_tickets_sold_mtd,
        sum(a.museum_attendance)                                                            as museum_attendance_mtd
    from agg a inner join as_of
        on year(a.report_date)  = year(as_of.report_date)
       and month(a.report_date) = month(as_of.report_date)
       and a.report_date       <= as_of.report_date
),
ytd_totals as (
    select
        sum(a.total_admissions_revenue)                                                     as total_admissions_revenue_ytd,
        sum(a.ticket_revenue)                                                               as ticket_revenue_ytd,
        sum(a.total_tickets_sold)                                                           as total_tickets_sold_ytd,
        sum(a.museum_attendance)                                                            as museum_attendance_ytd
    from agg a inner join as_of
        on year(a.report_date) = year(as_of.report_date)
       and a.report_date      <= as_of.report_date
),
budget_mtd as (
    select
        sum(b.total_admissions_revenue)                                                     as total_admissions_revenue_mtd,
        sum(b.total_tickets_sold)                                                           as total_tickets_sold_mtd
    from bagg b
    where b.report_date >= date_trunc('month', (select report_date from as_of))
      and b.report_date <= (select report_date from as_of)
),
budget_ytd as (
    select
        sum(b.total_admissions_revenue)                                                     as total_admissions_revenue_ytd,
        sum(b.total_tickets_sold)                                                           as total_tickets_sold_ytd
    from bagg b
    where b.report_date >= date_trunc('year', (select report_date from as_of))
      and b.report_date <= (select report_date from as_of)
),

trailing_7d as (
    select
        regr_slope(a.total_admissions_revenue, datediff('day', a.report_date, (select report_date from as_of))) as admissions_revenue_slope,
        regr_slope(a.total_tickets_sold,       datediff('day', a.report_date, (select report_date from as_of))) as tickets_slope,
        regr_slope(a.museum_attendance,        datediff('day', a.report_date, (select report_date from as_of))) as attendance_slope
    from agg a
    where a.report_date between dateadd('day', -6, (select report_date from as_of))
                            and (select report_date from as_of)
),

line_items as (
    select
        line_item, line_label, actual_val, budget_val, prior_val,
        div0(actual_val - budget_val, nullif(abs(budget_val), 0))                           as var_pct,
        actual_val - budget_val                                                             as var_amount,
        div0(actual_val - prior_val,  nullif(abs(prior_val),  0))                           as dod_pct,
        actual_val - prior_val                                                              as dod_amount
    from (
        {% for alias, code, label in headline_lines %}
        select '{{ alias }}' as line_item, '{{ label }}' as line_label,
               t.{{ alias }} as actual_val, bt.{{ alias }} as budget_val, p.{{ alias }} as prior_val
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
                {% for alias, code, label in headline_lines %}
                '{{ alias }}', object_construct(
                    'label',      '{{ label }}',
                    'actual',     t.{{ alias }},
                    'budget',     bt.{{ alias }},
                    'var_amount', round(t.{{ alias }} - bt.{{ alias }}, 2),
                    'var_pct',    round(div0(t.{{ alias }} - bt.{{ alias }}, nullif(abs(bt.{{ alias }}), 0)), 4),
                    'dod_pct',    round(div0(t.{{ alias }} - p.{{ alias }},  nullif(abs(p.{{ alias }}),  0)), 4),
                    'wow_pct',    round(div0(t.{{ alias }} - w.{{ alias }},  nullif(abs(w.{{ alias }}),  0)), 4),
                    'yoy_pct',    round(div0(t.{{ alias }} - py.{{ alias }}, nullif(abs(py.{{ alias }}), 0)), 4)
                ){% if not loop.last %},{% endif %}
                {% endfor %}
            ),

            -- Ratio-of-sums from the carried components. This is the ONLY place
            -- the Earned Income ratio is divided.
            'ratios', object_construct(
                {% for alias, code, label, num, den in ratio_lines %}
                '{{ alias }}', object_construct(
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
                'total_admissions_revenue_mtd',        pt.total_admissions_revenue_mtd,
                'total_admissions_revenue_ytd',        yt.total_admissions_revenue_ytd,
                'budget_total_admissions_revenue_mtd', bm.total_admissions_revenue_mtd,
                'budget_total_admissions_revenue_ytd', by2.total_admissions_revenue_ytd,
                'total_tickets_sold_mtd',              pt.total_tickets_sold_mtd,
                'total_tickets_sold_ytd',              yt.total_tickets_sold_ytd,
                'budget_total_tickets_sold_mtd',       bm.total_tickets_sold_mtd,
                'budget_total_tickets_sold_ytd',       by2.total_tickets_sold_ytd,
                'ticket_revenue_mtd',                  pt.ticket_revenue_mtd,
                'ticket_revenue_ytd',                  yt.ticket_revenue_ytd,
                'museum_attendance_mtd',               pt.museum_attendance_mtd,
                'museum_attendance_ytd',               yt.museum_attendance_ytd
            ),

            'direction_7d', object_construct(
                'total_admissions_revenue', case when tr.admissions_revenue_slope > 0 then 'rising' when tr.admissions_revenue_slope < 0 then 'falling' else 'flat' end,
                'total_tickets_sold',       case when tr.tickets_slope            > 0 then 'rising' when tr.tickets_slope            < 0 then 'falling' else 'flat' end,
                'museum_attendance',        case when tr.attendance_slope         > 0 then 'rising' when tr.attendance_slope         < 0 then 'falling' else 'flat' end
            ),

            'unavailable_lines', array_construct(
                'EST_OPERATING_EXPENSES', 'TOTAL_OPERATING_EXPENSES'
            ),

            'partial_lines', array_construct(
                'TICKETS', 'TICKET_REVENUE', 'AVG_TICKET_PRICE',
                'CITYPASS_TICKETS', 'CITYPASS_REVENUE',
                'TOTAL_TICKETS_SOLD', 'TOTAL_ADMISSIONS_REVENUE'
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
