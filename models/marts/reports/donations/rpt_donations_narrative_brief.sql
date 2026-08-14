-- Marts report: deterministic narrative brief — pre-computed Donations facts for the Cortex prompt
-- ---------------------------------------------------------------------------
-- Domain: donations / AI narrative
-- Grain: one row per report_date (one row overall — the latest actuals date)
--
-- Twin of rpt_retail_narrative_brief and rpt_dpr_narrative_brief. Assembles ONE
-- per-day JSON brief of the Donations Analysis Report: the nine donation lines
-- with a live source, their day-over-day / same-weekday-last-week / same-date-
-- last-year movements, MTD and YTD totals, the 7-day direction of the two
-- largest lines, the four per-visitor ratios carried as numerator + denominator
-- AND resolved at day grain, and the top movers. The LLM narrates ONLY this
-- brief -- it does not analyse and it does not compute. Every sentence in
-- rpt_donations_narrative traces to a field here, which is why this model, not
-- the LLM output, is the thing under test.
--
-- NO BUDGET. The Donations Analysis Report has no goal column (see
-- rpt_donations_report_long), so the brief carries no variance-to-budget and
-- the prompt is told not to mention budget.
--
-- DELIBERATE OMISSIONS. The vendor-cafe line (cafe_donations) is a typed NULL
-- placeholder with no data feed and is excluded from the brief entirely rather
-- than narrated as a zero. No cross-source donations TOTAL appears: legacy
-- publishes two incompatible roll-ups and choosing between them is an ADR-005
-- decision (owner: Chris Wogas) that 8.9.0 does not make. The brief leads with
-- ticketing donations, the largest single line.
--
-- ADR-004: all analysis logic lives in this model, not in the prompt.

{{ config(materialized='view') }}

{#- Donation lines the narrative may discuss. Vendor cafe excluded (stub). -#}
{% set headline_lines = [
    ('ticketing_donations', 'Ticketing Donations'),
    ('mus_store_don',       'Museum Store Donations'),
    ('retail_cart_don',     'Retail Cart Donations'),
    ('vs_cart_don',         'Visitor Services Cart Donations'),
    ('coatcheck_don',       'Coat Check Donations'),
    ('mus_exit_don',        'Museum Exit Donations'),
    ('cafe1_donations',     'Museum Cafe Donations'),
    ('shopify_don',         'E-Commerce Donation Ask'),
    ('vesey_donations',     'Vesey Street Donations')
] %}

{#- Per-visitor ratios: label -> (numerator expression, denominator expr) on -#}
{#- the `today` CTE, alias t. Fully qualified: the brief joins nine          -#}
{#- relations, so an unqualified column here would be ambiguous.            -#}
{#- Carried as components AND resolved at this one-day grain, which is a     -#}
{#- display grain, so the ratio rule is satisfied.                           -#}
{% set per_cap_lines = [
    ('ms_don_per_store_visitor',      'Museum Store Donations / Store Visitor',   't.mus_store_don',                     't.mus_store_visitors'),
    ('ms_don_per_mus_visitor',        'Museum Store Donations / Museum Visitor',  't.mus_store_don',                     't.mus_attendance'),
    ('cart_don_per_mem_only_visitor', 'Cart Donations / Memorial Only Visitor',   '(t.retail_cart_don + t.vs_cart_don)', 't.mem_only_visitors'),
    ('coatcheck_don_per_mus_visitor', 'Coat Check Donations / Museum Visitor',    't.coatcheck_don',                     't.mus_attendance')
] %}

with agg as (
    select * from {{ ref('fct_donations') }}
),

as_of as (
    select max(date_value) as report_date
    from agg
    where date_value < current_date()
),

today as (
    select a.* from agg a inner join as_of on a.date_value = as_of.report_date
),

prior_day as (
    select a.*
    from agg a
    where a.date_value = (
        select max(date_value) from agg
        where date_value < (select report_date from as_of)
    )
),

prior_week as (
    select a.* from agg a inner join as_of on a.date_value = dateadd('day', -7, as_of.report_date)
),

prior_year as (
    select a.* from agg a inner join as_of on a.date_value = dateadd('day', -364, as_of.report_date)
),

period_totals as (
    select
        {% for col, label in headline_lines %}
        sum(a.{{ col }}) as {{ col }}_mtd{% if not loop.last %},{% endif %}
        {% endfor %}
    from agg a inner join as_of
        on year(a.date_value)  = year(as_of.report_date)
       and month(a.date_value) = month(as_of.report_date)
       and a.date_value       <= as_of.report_date
),

ytd_totals as (
    select
        {% for col, label in headline_lines %}
        sum(a.{{ col }}) as {{ col }}_ytd{% if not loop.last %},{% endif %}
        {% endfor %}
    from agg a inner join as_of
        on year(a.date_value) = year(as_of.report_date)
       and a.date_value      <= as_of.report_date
),

trailing_7d as (
    select
        regr_slope(a.ticketing_donations, datediff('day', a.date_value, (select report_date from as_of))) as ticketing_slope,
        regr_slope(a.mus_store_don,       datediff('day', a.date_value, (select report_date from as_of))) as mus_store_slope
    from agg a
    where a.date_value between dateadd('day', -6, (select report_date from as_of))
                           and (select report_date from as_of)
),

-- Movers across the headline lines. Day-over-day and same-weekday-last-week,
-- since donation lines are strongly weekday-shaped.
line_items as (
    select
        line_item,
        line_label,
        actual_val,
        prior_val,
        week_val,
        actual_val - prior_val                                          as dod_amount,
        div0(actual_val - prior_val, nullif(abs(prior_val), 0))         as dod_pct,
        actual_val - week_val                                           as wow_amount,
        div0(actual_val - week_val,  nullif(abs(week_val),  0))         as wow_pct
    from (
        {% for col, label in headline_lines %}
        select '{{ col }}' as line_item, '{{ label }}' as line_label,
               t.{{ col }} as actual_val, p.{{ col }} as prior_val, w.{{ col }} as week_val
        from today t
        left join prior_day  p on true
        left join prior_week w on true
        {% if not loop.last %}union all{% endif %}
        {% endfor %}
    )
    where actual_val is not null and actual_val != 0
),

top_dod_movers as (
    select array_agg(object_construct('line', line_label, 'dod_pct', round(dod_pct, 4), 'dod_amount', round(dod_amount, 2)))
           within group (order by abs(dod_amount) desc) as arr
    from (select * from line_items where prior_val is not null order by abs(dod_amount) desc limit 3)
),

top_wow_movers as (
    select array_agg(object_construct('line', line_label, 'wow_pct', round(wow_pct, 4), 'wow_amount', round(wow_amount, 2)))
           within group (order by abs(wow_amount) desc) as arr
    from (select * from line_items where week_val is not null order by abs(wow_amount) desc limit 3)
),

brief as (
    select
        t.date_value as report_date,
        object_construct(
            'report_date', t.date_value::varchar,
            'is_commemoration_day', t.is_commemoration_day,
            'in_commemoration_window', (t.date_value between
                date_from_parts(year(t.date_value), 9, 6) and
                date_from_parts(year(t.date_value), 9, 16)),

            'attendance', object_construct(
                'museum_attendance',     t.mus_attendance,
                'memorial_attendance',   t.mem_attendance,
                'memorial_only_visitors', t.mem_only_visitors,
                'museum_store_visitors', t.mus_store_visitors,
                'vesey_visitors',        t.vesey_visitors
            ),

            'donations', object_construct(
                {% for col, label in headline_lines %}
                '{{ col }}', object_construct(
                    'label',   '{{ label }}',
                    'actual',  t.{{ col }},
                    'dod_pct', round(div0(t.{{ col }} - p.{{ col }},  nullif(abs(p.{{ col }}),  0)), 4),
                    'wow_pct', round(div0(t.{{ col }} - w.{{ col }},  nullif(abs(w.{{ col }}),  0)), 4),
                    'yoy_pct', round(div0(t.{{ col }} - py.{{ col }}, nullif(abs(py.{{ col }}), 0)), 4),
                    'mtd',     pt.{{ col }}_mtd,
                    'ytd',     yt.{{ col }}_ytd
                ){% if not loop.last %},{% endif %}
                {% endfor %}
            ),

            -- Per-visitor ratios. Numerator and denominator are carried so the
            -- narrative can restate them; the resolved value is the day-grain
            -- ratio-of-sums, which at one day is the ratio itself.
            'per_visitor', object_construct(
                {% for key, label, num, den in per_cap_lines %}
                '{{ key }}', object_construct(
                    'label',       '{{ label }}',
                    'numerator',   {{ num }},
                    'denominator', {{ den }},
                    'value',       round(div0({{ num }}, nullif({{ den }}, 0)), 4)
                ){% if not loop.last %},{% endif %}
                {% endfor %}
            ),

            'direction_7d', object_construct(
                'ticketing_donations', case when tr.ticketing_slope > 0 then 'rising'
                                            when tr.ticketing_slope < 0 then 'falling'
                                            else 'flat' end,
                'museum_store_donations', case when tr.mus_store_slope > 0 then 'rising'
                                               when tr.mus_store_slope < 0 then 'falling'
                                               else 'flat' end
            ),

            'top_dod_movers', tdm.arr,
            'top_wow_movers', twm.arr,

            'data_gaps', array_construct(
                'Vendor-era cafe donations (911dw.cafe_performance, 2018-2023) have no data feed and are excluded.',
                'Museum store, Vesey and memorial-cart donation cohorts use the donation category, not the legacy SKU whitelist.'
            )
        ) as brief_json
    from today t
    left join prior_day  p  on true
    left join prior_week w  on true
    left join prior_year py on true
    cross join period_totals pt
    cross join ytd_totals    yt
    cross join trailing_7d   tr
    cross join top_dod_movers tdm
    cross join top_wow_movers twm
)

select report_date, brief_json from brief
