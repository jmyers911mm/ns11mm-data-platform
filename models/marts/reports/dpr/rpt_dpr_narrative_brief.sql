-- Marts report: deterministic narrative brief — pre-computed DPR facts for the AI_COMPLETE prompt
-- ---------------------------------------------------------------------------
-- Domain: DPR / AI narrative
-- Grain: one row per report_date
--
-- Assembles a JSON brief of actuals, budget, day-over-day, week-over-week,
-- MTD/YTD context, direction flags, and top movers for each DPR day.
-- The LLM receives ONLY this brief — it narrates pre-computed facts, it does
-- not do analysis. Every sentence in the narrative traces to a field here.
--
-- ADR-004: all analysis logic lives in this model, not in the prompt or PBI.

{{ config(materialized='view') }}

{% set headline_lines = [
    ('memorial_attendance',       'Memorial Attendance'),
    ('museum_attendance',         'Museum Attendance'),
    ('admission_revenue',         'Total Admission Revenue'),
    ('tickets_sold',              'Tickets Sold'),
    ('ticket_revenue',            'Ticket Revenue'),
    ('pass_revenue',              'Pass Revenue'),
    ('mus_guided_tour_revenue',   'Museum Guided Tour Revenue'),
    ('mem_guided_tour_revenue',   'Memorial Guided Tour Revenue'),
    ('mem_mus_tour_revenue',      'Mem+Mus Tour Revenue'),
    ('revealed_tour_revenue',     'Revealed Tour Revenue'),
    ('virtual_tour_revenue',      'Virtual Tour Revenue'),
    ('mus_store_gross_profit',    'Museum Store Gross Profit'),
    ('retail_carts_gross_profit', 'Retail Carts Gross Profit'),
    ('cafe_profit',               'Cafe Gross Profit'),
    ('audio_tour_headset',        'Audio Tour & Headset Revenue'),
    ('cart_donation_ask',         'Cart Donation Ask'),
    ('box_office_mem_don',        'Box Office Memorial Donations'),
    ('donation_box',              'Donation Box'),
    ('ticketing_donations',       'Ticketing Donations')
] %}

with actuals as (
    select * from {{ ref('rpt_dpr_powerbi') }}
),

budget as (
    select * from {{ ref('rpt_dpr_budget_daily') }}
),

-- Report date: previous day (the DPR covers yesterday's performance)
as_of as (
    select max(report_date) as report_date
    from actuals
    where report_date < current_date()
),

-- Today's actuals
today as (
    select a.*
    from actuals a
    inner join as_of on a.report_date = as_of.report_date
),

-- Prior day (most recent date before today with data)
prior_day as (
    select a.*
    from actuals a
    where a.report_date = (
        select max(report_date)
        from actuals
        where report_date < (select report_date from as_of)
    )
),

-- Same day prior week (7 days back)
prior_week as (
    select a.*
    from actuals a
    inner join as_of on a.report_date = dateadd('day', -7, as_of.report_date)
),

-- Year-over-year: same weekday prior year (364 days = 52 weeks)
prior_year as (
    select a.*
    from actuals a
    inner join as_of on a.report_date = dateadd('day', -364, as_of.report_date)
),

-- Budget for today
budget_today as (
    select b.*
    from budget b
    inner join as_of on b.report_date = as_of.report_date
),

-- MTD and YTD from actuals
period_totals as (
    select
        sum(admission_revenue)         as admission_revenue_mtd,
        sum(mus_store_gross_profit)    as mus_store_mtd,
        sum(retail_carts_gross_profit) as retail_carts_mtd,
        sum(cafe_profit)               as cafe_mtd,
        sum(memorial_attendance)       as mem_attendance_mtd,
        sum(museum_attendance)         as mus_attendance_mtd
    from actuals a
    inner join as_of on a.calendar_year = (select calendar_year from today)
        and a.calendar_month = (select calendar_month from today)
        and a.report_date <= as_of.report_date
),

ytd_totals as (
    select
        sum(admission_revenue)         as admission_revenue_ytd,
        sum(mus_store_gross_profit)    as mus_store_ytd,
        sum(retail_carts_gross_profit) as retail_carts_ytd,
        sum(cafe_profit)               as cafe_ytd,
        sum(memorial_attendance)       as mem_attendance_ytd,
        sum(museum_attendance)         as mus_attendance_ytd
    from actuals a
    inner join as_of on a.calendar_year = (select calendar_year from today)
        and a.report_date <= as_of.report_date
),

-- Budget MTD/YTD
budget_mtd as (
    select
        sum(admission_revenue)         as admission_revenue_mtd,
        sum(mus_store_gross_profit)    as mus_store_mtd,
        sum(retail_carts_gross_profit) as retail_carts_mtd,
        sum(cafe_profit)               as cafe_mtd,
        sum(memorial_attendance)       as mem_attendance_mtd,
        sum(museum_attendance)         as mus_attendance_mtd
    from budget b
    where b.report_date >= date_trunc('month', (select report_date from as_of))
      and b.report_date <= (select report_date from as_of)
),

budget_ytd as (
    select
        sum(admission_revenue)         as admission_revenue_ytd,
        sum(mus_store_gross_profit)    as mus_store_ytd,
        sum(retail_carts_gross_profit) as retail_carts_ytd,
        sum(cafe_profit)               as cafe_ytd,
        sum(memorial_attendance)       as mem_attendance_ytd,
        sum(museum_attendance)         as mus_attendance_ytd
    from budget b
    where b.report_date >= date_trunc('year', (select report_date from as_of))
      and b.report_date <= (select report_date from as_of)
),

-- 7-day trailing direction (slope sign: positive = rising, negative = falling)
trailing_7d as (
    select
        regr_slope(admission_revenue, datediff('day', report_date, (select report_date from as_of)))   as admission_slope,
        regr_slope(museum_attendance, datediff('day', report_date, (select report_date from as_of)))   as mus_att_slope,
        regr_slope(memorial_attendance, datediff('day', report_date, (select report_date from as_of))) as mem_att_slope,
        regr_slope(mus_store_gross_profit, datediff('day', report_date, (select report_date from as_of))) as retail_slope
    from actuals a
    where a.report_date between dateadd('day', -6, (select report_date from as_of))
                            and (select report_date from as_of)
),

-- Top movers: largest absolute budget variance and largest absolute DoD change
-- Unpivot actuals and budget into line items for ranking
line_items as (
    select
        line_item,
        line_label,
        actual_val,
        budget_val,
        prior_val,
        yoy_val,
        div0(actual_val - budget_val, nullif(abs(budget_val), 0)) as var_pct,
        actual_val - budget_val                                    as var_amount,
        div0(actual_val - prior_val, nullif(abs(prior_val), 0))   as dod_pct,
        actual_val - prior_val                                     as dod_amount,
        div0(actual_val - yoy_val, nullif(abs(yoy_val), 0))       as yoy_pct,
        actual_val - yoy_val                                       as yoy_amount
    from (
        {% for col, label in headline_lines %}
        select
            '{{ col }}'    as line_item,
            '{{ label }}'  as line_label,
            t.{{ col }}    as actual_val,
            {% if col in ['virtual_tour_revenue', 'cart_donation_ask', 'box_office_mem_don', 'donation_box', 'ticketing_donations'] %}
            null           as budget_val,
            {% else %}
            bt.{{ col }}   as budget_val,
            {% endif %}
            p.{{ col }}    as prior_val,
            py.{{ col }}   as yoy_val
        from today t
        cross join prior_day p
        cross join budget_today bt
        left join prior_year py on true
        {% if not loop.last %}union all{% endif %}
        {% endfor %}
    )
    where actual_val is not null and actual_val != 0
),

top_budget_movers as (
    select array_agg(object_construct(
        'line', line_label,
        'var_pct', round(var_pct, 4),
        'var_amount', round(var_amount, 2)
    )) within group (order by abs(var_amount) desc) as arr
    from (select * from line_items where budget_val is not null order by abs(var_amount) desc limit 3)
),

top_dod_movers as (
    select array_agg(object_construct(
        'line', line_label,
        'dod_pct', round(dod_pct, 4),
        'dod_amount', round(dod_amount, 2)
    )) within group (order by abs(dod_amount) desc) as arr
    from (select * from line_items where prior_val is not null order by abs(dod_amount) desc limit 3)
),

-- Assemble the brief
brief as (
    select
        t.report_date,
        object_construct(
            'report_date', t.report_date::varchar,
            'day_name', t.day_name,
            'is_commemoration_day', t.is_commemoration_day,
            'in_commemoration_window', (t.report_date between
                date_from_parts(year(t.report_date), 9, 6) and
                date_from_parts(year(t.report_date), 9, 16)),

            'metrics', object_construct(
                {% for col, label in headline_lines %}
                '{{ col }}', object_construct(
                    'label', '{{ label }}',
                    'actual', t.{{ col }},
                    {% if col in ['virtual_tour_revenue', 'cart_donation_ask', 'box_office_mem_don', 'donation_box', 'ticketing_donations'] %}
                    'budget', null,
                    {% else %}
                    'budget', bt.{{ col }},
                    {% endif %}
                    'var_pct', {% if col in ['virtual_tour_revenue', 'cart_donation_ask', 'box_office_mem_don', 'donation_box', 'ticketing_donations'] %}null{% else %}round(div0(t.{{ col }} - bt.{{ col }}, nullif(abs(bt.{{ col }}), 0)), 4){% endif %},
                    'dod_pct', round(div0(t.{{ col }} - p.{{ col }}, nullif(abs(p.{{ col }}), 0)), 4),
                    'wow_pct', round(div0(t.{{ col }} - w.{{ col }}, nullif(abs(w.{{ col }}), 0)), 4),
                    'yoy_pct', round(div0(t.{{ col }} - py.{{ col }}, nullif(abs(py.{{ col }}), 0)), 4)
                ){% if not loop.last %},{% endif %}
                {% endfor %}
            ),

            'total_estimated_revenue', object_construct(
                'actual', round(coalesce(t.admission_revenue, 0)
                    + coalesce(t.mus_guided_tour_revenue, 0)
                    + coalesce(t.mem_guided_tour_revenue, 0)
                    + coalesce(t.mem_mus_tour_revenue, 0)
                    + coalesce(t.revealed_tour_revenue, 0)
                    + coalesce(t.virtual_tour_revenue, 0)
                    + coalesce(t.virtual_yf_tour_revenue, 0)
                    + coalesce(t.mus_store_gross_profit, 0)
                    + coalesce(t.retail_carts_gross_profit, 0)
                    + coalesce(t.cafe_profit, 0)
                    + coalesce(t.audio_tour_headset, 0), 2),
                'budget', round(coalesce(bt.admission_revenue, 0)
                    + coalesce(bt.mus_guided_tour_revenue, 0)
                    + coalesce(bt.mem_guided_tour_revenue, 0)
                    + coalesce(bt.mem_mus_tour_revenue, 0)
                    + coalesce(bt.revealed_tour_revenue, 0)
                    + coalesce(bt.virtual_yf_tour_revenue, 0)
                    + coalesce(bt.mus_store_gross_profit, 0)
                    + coalesce(bt.retail_carts_gross_profit, 0)
                    + coalesce(bt.cafe_profit, 0)
                    + coalesce(bt.audio_tour_headset, 0), 2)
            ),

            'period_context', object_construct(
                'admission_revenue_mtd', pt.admission_revenue_mtd,
                'admission_revenue_ytd', yt.admission_revenue_ytd,
                'budget_admission_revenue_mtd', bm.admission_revenue_mtd,
                'budget_admission_revenue_ytd', by2.admission_revenue_ytd,
                'mus_attendance_mtd', pt.mus_attendance_mtd,
                'mus_attendance_ytd', yt.mus_attendance_ytd,
                'budget_mus_attendance_mtd', bm.mus_attendance_mtd
            ),

            'direction_7d', object_construct(
                'admission_revenue', case when tr.admission_slope > 0 then 'rising'
                                          when tr.admission_slope < 0 then 'falling'
                                          else 'flat' end,
                'museum_attendance', case when tr.mus_att_slope > 0 then 'rising'
                                          when tr.mus_att_slope < 0 then 'falling'
                                          else 'flat' end,
                'memorial_attendance', case when tr.mem_att_slope > 0 then 'rising'
                                            when tr.mem_att_slope < 0 then 'falling'
                                            else 'flat' end,
                'retail', case when tr.retail_slope > 0 then 'rising'
                               when tr.retail_slope < 0 then 'falling'
                               else 'flat' end
            ),

            'top_budget_movers', tbm.arr,
            'top_dod_movers', tdm.arr
        ) as brief_json
    from today t
    cross join prior_day p
    cross join budget_today bt
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

select report_date, brief_json
from brief
