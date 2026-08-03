-- Marts report: long/unpivoted Tracker serving shape (actual + projection per line item)
-- ---------------------------------------------------------------------------
-- Domain: DPR / cross-domain
-- Grain:  one row per report_date x line_item_code
--
-- Tidy Memorial & Museum Daily Tracker presentation: unions
-- rpt_tracker_powerbi (actual) and rpt_tracker_budget_daily (projection) into
-- one long shape in the style of rpt_dpr_report_long / rpt_retail_report_long.
-- Feeds the Power BI Tracker YTD scorecard, which joins dim_tracker_line_item
-- for layout and dim_date for the YTD window (YTD is DAX time intelligence
-- over these day-grain rows — never materialized).
--   amount / numerator / denominator                      -> ACTUAL
--   budget_amount / budget_numerator / budget_denominator -> PROJECTION
-- NOTE: unlike the DPR/Retail matrices (scenario pivoted to columns), the
-- tracker PRINTS the projection as its own row — so each "... Projection"
-- line has its own line_item_code carrying the projection in budget_amount
-- (amount NULL), and the actual lines carry no budget. No pairing logic in
-- Power BI.
-- NOTE: the Memorial-vs-Museum REVENUE split (Total Memorial/Museum Revenue,
-- both per-cap numerators) is an open business-rule seam: not derivable from
-- the DPR lines, emitted as typed NULL — never guessed. The per-cap
-- denominators (attendance) are carried so the ratios light up when the split
-- rule lands. The Earned Revenue Projection excludes donations and virtual-
-- tour revenue (not in the budget — see rpt_tracker_budget_daily).
--
-- ADR-004: all business logic in dbt, never Power BI.

{{ config(materialized='view', grants={'select': ['POWERBI_ROLE']}) }}

-- =========================================================== ACTUAL
with a_wide as ( select * from {{ ref('rpt_tracker_powerbi') }} ),

actual_long as (
    -- Total Earned Revenue composite = the DPR TOTAL_ESTIMATED_REVENUE
    -- component set (admissions + all tours + retail & cafe profit + audio
    -- + all donation components), sourced from rpt_dpr_report_long.
    select report_date, 'TOTAL_EARNED_REVENUE' as line_item_code,
           cast( admission_revenue
               + revealed_tour_revenue + mem_mus_tour_revenue + mus_guided_tour_revenue
                 + mem_guided_tour_revenue + virtual_tour_revenue
               + mus_store_gross_profit + retail_carts_gross_profit
               + cafe_profit + audio_tour_headset
               + cart_donation_ask + box_office_mem_don + donation_box + ecom_donation_ask
               + ticketing_donations + box_office_mus_exit_don + coatcheck_don
                 + mus_store_don + mus_exit_don + cafe_don as number(38,4)) as amount,
           cast(null as number(38,4)) as numerator, cast(null as number(38,4)) as denominator
    from a_wide
    union all
    select report_date, 'MEMORIAL_ATTENDANCE',
           cast(memorial_attendance as number(38,4)), null, null from a_wide
    union all
    select report_date, 'TICKETS_SOLD',
           cast(tickets_sold as number(38,4)), null, null from a_wide
    union all
    -- Memorial-vs-Museum revenue split: open business-rule seam -> typed NULL
    select report_date, 'TOTAL_MEMORIAL_REVENUE',
           cast(null as number(38,4)), null, null from a_wide
    union all
    select report_date, 'TOTAL_MUSEUM_REVENUE',
           cast(null as number(38,4)), null, null from a_wide
    union all
    -- Per-cap ratios: numerator is the stubbed revenue split (typed NULL until
    -- the split rule lands); denominator = the attendance component
    select report_date, 'REV_PER_CAP_MEMORIAL',
           cast(null as number(38,4)),
           cast(null as number(38,4)),
           cast(memorial_attendance as number(38,4)) from a_wide
    union all
    select report_date, 'REV_PER_CAP_MUSEUM',
           cast(null as number(38,4)),
           cast(null as number(38,4)),
           cast(museum_attendance as number(38,4)) from a_wide
),

-- =========================================================== PROJECTION
b_wide as ( select * from {{ ref('rpt_tracker_budget_daily') }} ),

budget_long as (
    -- Earned Revenue Projection: budgeted components only — donations and
    -- virtual-tour revenue are NULL in the budget conform and excluded here.
    select report_date, 'EARNED_REVENUE_PROJECTION' as line_item_code,
           cast( admission_revenue
               + revealed_tour_revenue + mem_mus_tour_revenue + mus_guided_tour_revenue
                 + mem_guided_tour_revenue
               + mus_store_gross_profit + retail_carts_gross_profit
               + cafe_profit + audio_tour_headset as number(38,4)) as budget_amount,
           cast(null as number(38,4)) as budget_numerator, cast(null as number(38,4)) as budget_denominator
    from b_wide
    union all
    select report_date, 'MEMORIAL_ATTENDANCE_PROJECTION',
           cast(memorial_attendance as number(38,4)), null, null from b_wide
    union all
    select report_date, 'TICKETS_SOLD_PROJECTION',
           cast(tickets_sold as number(38,4)), null, null from b_wide
)

-- =========================================================== MERGE
select
    coalesce(a.report_date, b.report_date)       as report_date,
    coalesce(a.line_item_code, b.line_item_code) as line_item_code,
    a.amount,
    a.numerator,
    a.denominator,
    b.budget_amount,
    b.budget_numerator,
    b.budget_denominator
from actual_long a
full outer join budget_long b
    on  a.report_date    = b.report_date
    and a.line_item_code = b.line_item_code
