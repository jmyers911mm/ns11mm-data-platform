-- Marts report: deterministic narrative brief — pre-computed Tracker facts for the AI_COMPLETE prompt
-- ---------------------------------------------------------------------------
-- Domain: DPR / cross-domain / AI narrative
-- Grain: one row per report_date
--
-- Sibling of rpt_dpr_narrative_brief, YTD framing to match the Memorial &
-- Museum Daily Tracker: calendar-year-to-date total earned revenue vs the
-- projection (with variance pct), YTD memorial and museum attendance vs
-- projection, YTD tickets sold vs projection, and the last-7-days direction
-- of earned revenue and attendance. The earned-revenue composite and the
-- projection component set are the same authored definitions used in
-- rpt_tracker_report_long (projection excludes donations and virtual-tour
-- revenue — not in the budget). The LLM narrates ONLY this brief — it does
-- not analyze. Every sentence traces to a field here.
--
-- ADR-004: all analysis logic lives in this model, not the prompt or Power BI.

{{ config(materialized='view') }}

with
-- Daily actuals with the earned-revenue composite resolved (DPR
-- TOTAL_ESTIMATED_REVENUE component set — see rpt_tracker_report_long)
actuals as (
    select
        report_date,
        memorial_attendance,
        museum_attendance,
        tickets_sold,
        coalesce(admission_revenue, 0)
          + coalesce(revealed_tour_revenue, 0) + coalesce(mem_mus_tour_revenue, 0)
          + coalesce(mus_guided_tour_revenue, 0) + coalesce(mem_guided_tour_revenue, 0)
          + coalesce(virtual_tour_revenue, 0)
          + coalesce(mus_store_gross_profit, 0) + coalesce(retail_carts_gross_profit, 0)
          + coalesce(cafe_profit, 0) + coalesce(audio_tour_headset, 0)
          + coalesce(cart_donation_ask, 0) + coalesce(box_office_mem_don, 0)
          + coalesce(donation_box, 0) + coalesce(ecom_donation_ask, 0)
          + coalesce(ticketing_donations, 0) + coalesce(box_office_mus_exit_don, 0)
          + coalesce(coatcheck_don, 0) + coalesce(mus_store_don, 0)
          + coalesce(mus_exit_don, 0) + coalesce(cafe_don, 0)   as earned_revenue
    from {{ ref('rpt_tracker_powerbi') }}
),

-- Daily projection (budgeted components only — donations and virtual
-- excluded, they are NULL in the budget conform)
projection as (
    select
        report_date,
        memorial_attendance,
        museum_attendance,
        tickets_sold,
        coalesce(admission_revenue, 0)
          + coalesce(revealed_tour_revenue, 0) + coalesce(mem_mus_tour_revenue, 0)
          + coalesce(mus_guided_tour_revenue, 0) + coalesce(mem_guided_tour_revenue, 0)
          + coalesce(mus_store_gross_profit, 0) + coalesce(retail_carts_gross_profit, 0)
          + coalesce(cafe_profit, 0) + coalesce(audio_tour_headset, 0)  as earned_revenue
    from {{ ref('rpt_tracker_budget_daily') }}
),

-- Report date: previous day (the tracker covers through yesterday)
as_of as (
    select max(report_date) as report_date
    from actuals
    where report_date < current_date()
),

-- Calendar-year-to-date actuals through the as-of date
ytd_actual as (
    select
        sum(a.earned_revenue)       as earned_revenue,
        sum(a.memorial_attendance)  as memorial_attendance,
        sum(a.museum_attendance)    as museum_attendance,
        sum(a.tickets_sold)         as tickets_sold
    from actuals a
    inner join as_of
        on year(a.report_date) = year(as_of.report_date)
       and a.report_date <= as_of.report_date
),

-- Calendar-year-to-date projection over the same window
ytd_projection as (
    select
        sum(p.earned_revenue)       as earned_revenue,
        sum(p.memorial_attendance)  as memorial_attendance,
        sum(p.museum_attendance)    as museum_attendance,
        sum(p.tickets_sold)         as tickets_sold
    from projection p
    inner join as_of
        on year(p.report_date) = year(as_of.report_date)
       and p.report_date <= as_of.report_date
),

-- 7-day trailing direction (slope sign: positive = rising, negative = falling)
trailing_7d as (
    select
        regr_slope(earned_revenue, datediff('day', report_date, (select report_date from as_of)))       as revenue_slope,
        regr_slope(memorial_attendance, datediff('day', report_date, (select report_date from as_of)))  as mem_att_slope,
        regr_slope(museum_attendance, datediff('day', report_date, (select report_date from as_of)))    as mus_att_slope
    from actuals a
    where a.report_date between dateadd('day', -6, (select report_date from as_of))
                            and (select report_date from as_of)
),

brief as (
    select
        ao.report_date,
        object_construct(
            'report_date', ao.report_date::varchar,
            'framing', 'calendar year-to-date through the report date; projection excludes donations and virtual-tour revenue (not budgeted)',

            'ytd_earned_revenue', object_construct(
                'actual', round(ya.earned_revenue, 2),
                'projection', round(yp.earned_revenue, 2),
                'var_amount', round(ya.earned_revenue - yp.earned_revenue, 2),
                'var_pct', round(div0(ya.earned_revenue - yp.earned_revenue, nullif(abs(yp.earned_revenue), 0)), 4)
            ),

            'ytd_memorial_attendance', object_construct(
                'actual', ya.memorial_attendance,
                'projection', yp.memorial_attendance,
                'var_pct', round(div0(ya.memorial_attendance - yp.memorial_attendance, nullif(abs(yp.memorial_attendance), 0)), 4)
            ),

            'ytd_museum_attendance', object_construct(
                'actual', ya.museum_attendance,
                'projection', yp.museum_attendance,
                'var_pct', round(div0(ya.museum_attendance - yp.museum_attendance, nullif(abs(yp.museum_attendance), 0)), 4)
            ),

            'ytd_tickets_sold', object_construct(
                'actual', ya.tickets_sold,
                'projection', yp.tickets_sold,
                'var_pct', round(div0(ya.tickets_sold - yp.tickets_sold, nullif(abs(yp.tickets_sold), 0)), 4)
            ),

            'direction_7d', object_construct(
                'earned_revenue', case when tr.revenue_slope > 0 then 'rising' when tr.revenue_slope < 0 then 'falling' else 'flat' end,
                'memorial_attendance', case when tr.mem_att_slope > 0 then 'rising' when tr.mem_att_slope < 0 then 'falling' else 'flat' end,
                'museum_attendance', case when tr.mus_att_slope > 0 then 'rising' when tr.mus_att_slope < 0 then 'falling' else 'flat' end
            )
        ) as brief_json
    from as_of ao
    cross join ytd_actual ya
    cross join ytd_projection yp
    cross join trailing_7d tr
)

select report_date, brief_json from brief
