-- models/marts/reports/rpt_dpr_report_long.sql
-- Tidy DPR presentation: one row per (report_date, line_item_code) carrying BOTH
-- actual and budget, with composites + the ratio resolved in SQL (ADR-004: no
-- business logic in Power BI). Power BI joins to dim_dpr_line_item for layout and
-- to dim_date for periods, and uses one display measure per scenario.
--
--   amount / numerator / denominator                 -> ACTUAL   (from rpt_dpr_powerbi)
--   budget_amount / budget_numerator / budget_denominator -> BUDGET (from rpt_dpr_budget_daily)
--
-- Budget is intentionally NULL for the two donation composites, Professional
-- Program Revenue, Total Estimated Revenue, and Virtual Tour Revenue (unmapped).

{{ config(materialized='view', grants={'select': ['POWERBI_ROLE']}) }}

-- =========================================================== ACTUAL
with a_wide as ( select * from {{ ref('rpt_dpr_powerbi') }} ),

a_prep as (
    select
        report_date,
        cast(memorial_attendance       as number(38,4)) as memorial_attendance,
        cast(museum_attendance         as number(38,4)) as museum_attendance,
        cast(tickets_sold              as number(38,4)) as tickets_sold,
        cast(ticket_revenue            as number(38,4)) as ticket_revenue,
        cast(pass_revenue              as number(38,4)) as pass_revenue,
        cast(admission_revenue         as number(38,4)) as admission_revenue,
        cast(revealed_tour_revenue     as number(38,4)) as revealed_tour_revenue,
        cast(mem_mus_tours             as number(38,4)) as mem_mus_tours,
        cast(mem_mus_tour_revenue      as number(38,4)) as mem_mus_tour_revenue,
        cast(museum_guided_tours       as number(38,4)) as museum_guided_tours,
        cast(mus_guided_tour_revenue   as number(38,4)) as mus_guided_tour_revenue,
        cast(memorial_guided_tours     as number(38,4)) as memorial_guided_tours,
        cast(mem_guided_tour_revenue   as number(38,4)) as mem_guided_tour_revenue,
        cast(virtual_tour_revenue      as number(38,4)) as virtual_tour_revenue,
        cast(mus_store_gross_profit    as number(38,4)) as mus_store_gross_profit,
        cast(retail_carts_gross_profit as number(38,4)) as retail_carts_gross_profit,
        cast(cafe_profit               as number(38,4)) as cafe_profit,
        cast(audio_tour_headset        as number(38,4)) as audio_tour_headset,
        cast(virtual_yf_tour_revenue   as number(38,4)) as virtual_yf_tour_revenue
    from a_wide
),

a_base as (
    select report_date, metric_col as line_item_code, amount,
           cast(null as number(38,4)) as numerator, cast(null as number(38,4)) as denominator
    from a_prep
    unpivot ( amount for metric_col in (
        memorial_attendance, museum_attendance, tickets_sold, ticket_revenue,
        pass_revenue, admission_revenue, revealed_tour_revenue, mem_mus_tours,
        mem_mus_tour_revenue, museum_guided_tours, mus_guided_tour_revenue,
        memorial_guided_tours, mem_guided_tour_revenue, virtual_tour_revenue,
        mus_store_gross_profit, retail_carts_gross_profit, cafe_profit,
        audio_tour_headset, virtual_yf_tour_revenue
    ) )
),

a_composite as (
    select report_date, 'TOTAL_TOUR_REVENUE' as line_item_code,
           cast(revealed_tour_revenue + mem_mus_tour_revenue + mus_guided_tour_revenue
                + mem_guided_tour_revenue + virtual_tour_revenue as number(38,4)) as amount,
           cast(null as number(38,4)) as numerator, cast(null as number(38,4)) as denominator from a_wide
    union all
    select report_date, 'TOTAL_RETAIL_GROSS_PROFIT',
           cast(mus_store_gross_profit + retail_carts_gross_profit as number(38,4)), null, null from a_wide
    union all
    select report_date, 'TOTAL_MEMORIAL_DONATIONS',
           cast(cart_donation_ask + box_office_mem_don + donation_box + ecom_donation_ask as number(38,4)), null, null from a_wide
    union all
    select report_date, 'TOTAL_MUSEUM_DONATIONS',
           cast(ticketing_donations + box_office_mus_exit_don + coatcheck_don
                + mus_store_don + mus_exit_don + cafe_don as number(38,4)), null, null from a_wide
    union all
    select report_date, 'TOTAL_ESTIMATED_REVENUE',
           cast( admission_revenue
               + revealed_tour_revenue + mem_mus_tour_revenue + mus_guided_tour_revenue
                 + mem_guided_tour_revenue + virtual_tour_revenue
               + mus_store_gross_profit + retail_carts_gross_profit
               + cafe_profit + audio_tour_headset
               + cart_donation_ask + box_office_mem_don + donation_box + ecom_donation_ask
               + ticketing_donations + box_office_mus_exit_don + coatcheck_don
                 + mus_store_don + mus_exit_don + cafe_don as number(38,4)), null, null from a_wide
),

a_ratio as (
    select report_date, 'AVG_TICKET_PRICE' as line_item_code,
           cast(null as number(38,4)) as amount,
           cast(admission_revenue as number(38,4)) as numerator,
           cast(tickets_sold as number(38,4)) as denominator
    from a_wide
),

actual_long as (
    select report_date, line_item_code, amount, numerator, denominator from a_base
    union all select report_date, line_item_code, amount, numerator, denominator from a_composite
    union all select report_date, line_item_code, amount, numerator, denominator from a_ratio
),

-- =========================================================== BUDGET
b_wide as ( select * from {{ ref('rpt_dpr_budget_daily') }} ),

b_prep as (
    select
        report_date,
        cast(memorial_attendance       as number(38,4)) as memorial_attendance,
        cast(museum_attendance         as number(38,4)) as museum_attendance,
        cast(tickets_sold              as number(38,4)) as tickets_sold,
        cast(ticket_revenue            as number(38,4)) as ticket_revenue,
        cast(pass_revenue              as number(38,4)) as pass_revenue,
        cast(admission_revenue         as number(38,4)) as admission_revenue,
        cast(early_access_tour_count   as number(38,4)) as early_access_tour_count,
        cast(revealed_tour_revenue     as number(38,4)) as revealed_tour_revenue,
        cast(mem_mus_tours             as number(38,4)) as mem_mus_tours,
        cast(mem_mus_tour_revenue      as number(38,4)) as mem_mus_tour_revenue,
        cast(museum_guided_tours       as number(38,4)) as museum_guided_tours,
        cast(mus_guided_tour_revenue   as number(38,4)) as mus_guided_tour_revenue,
        cast(memorial_guided_tours     as number(38,4)) as memorial_guided_tours,
        cast(mem_guided_tour_revenue   as number(38,4)) as mem_guided_tour_revenue,
        cast(mus_store_gross_profit    as number(38,4)) as mus_store_gross_profit,
        cast(retail_carts_gross_profit as number(38,4)) as retail_carts_gross_profit,
        cast(ecom_gross_profit         as number(38,4)) as ecom_gross_profit,
        cast(cafe_profit               as number(38,4)) as cafe_profit,
        cast(audio_tour_headset        as number(38,4)) as audio_tour_headset,
        cast(virtual_yf_tour_revenue   as number(38,4)) as virtual_yf_tour_revenue
    from b_wide
),

b_base as (
    select report_date, metric_col as line_item_code, amount,
           cast(null as number(38,4)) as numerator, cast(null as number(38,4)) as denominator
    from b_prep
    unpivot ( amount for metric_col in (
        memorial_attendance, museum_attendance, tickets_sold, ticket_revenue,
        pass_revenue, admission_revenue, early_access_tour_count, revealed_tour_revenue,
        mem_mus_tours, mem_mus_tour_revenue, museum_guided_tours, mus_guided_tour_revenue,
        memorial_guided_tours, mem_guided_tour_revenue,
        mus_store_gross_profit, retail_carts_gross_profit, ecom_gross_profit, cafe_profit,
        audio_tour_headset, virtual_yf_tour_revenue
    ) )
),

b_composite as (
    -- Total Tour Revenue (no virtual budget); Total Retail GP includes ecom (available in budget)
    select report_date, 'TOTAL_TOUR_REVENUE' as line_item_code,
           cast(revealed_tour_revenue + mem_mus_tour_revenue + mus_guided_tour_revenue
                + mem_guided_tour_revenue as number(38,4)) as amount,
           cast(null as number(38,4)) as numerator, cast(null as number(38,4)) as denominator from b_wide
    union all
    select report_date, 'TOTAL_RETAIL_GROSS_PROFIT',
           cast(mus_store_gross_profit + retail_carts_gross_profit + ecom_gross_profit as number(38,4)),
           null, null from b_wide
),

b_ratio as (
    select report_date, 'AVG_TICKET_PRICE' as line_item_code,
           cast(null as number(38,4)) as amount,
           cast(admission_revenue as number(38,4)) as numerator,
           cast(tickets_sold as number(38,4)) as denominator
    from b_wide
),

budget_long as (
    select report_date, line_item_code, amount as budget_amount,
           numerator as budget_numerator, denominator as budget_denominator from b_base
    union all select report_date, line_item_code, amount, numerator, denominator from b_composite
    union all select report_date, line_item_code, amount, numerator, denominator from b_ratio
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