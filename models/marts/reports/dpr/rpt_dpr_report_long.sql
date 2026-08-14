-- Marts report: long/unpivoted DPR serving shape (actual + budget per line item)
-- ---------------------------------------------------------------------------
-- Domain: DPR
-- Grain:  one row per report_date x line_item_code
--
-- Tidy DPR presentation: unpivots rpt_dpr_powerbi (actual) and
-- rpt_dpr_budget_daily (budget) into one long shape carrying BOTH scenarios,
-- with composites and the ratio resolved in SQL. Feeds the Power BI Daily
-- Performance Report matrix, which joins dim_dpr_line_item for layout and
-- dim_date for periods, and uses one display measure per scenario.
--   amount / numerator / denominator                      -> ACTUAL
--   budget_amount / budget_numerator / budget_denominator -> BUDGET
-- NOTE: budget is intentionally NULL for the two donation composites,
-- Professional Program Revenue, Total Estimated Revenue, and Virtual Tour
-- Revenue (unmapped).
--
-- 8.1.0 changes in this model:
--  1. TOTAL_MEMORIAL_DONATIONS and TOTAL_MUSEUM_DONATIONS are no longer
--     restated here. They are semantic-view metrics (DPR.sv.yaml) read off the
--     wrapper, per ADR-021's composite rule. TOTAL_MEMORIAL_DONATIONS also
--     changes definition to match the legacy line of record
--     (t_dpr_excel_data_update: ecom_don + don_box + cart_don_ask + mask_don):
--     MASK_DONATIONS is added, BOX_OFFICE_MEM_DON is removed. Before 8.1.0 the
--     two DPR serving surfaces disagreed -- rpt_dpr_mtd_ytd_long counted
--     mask donations inside TOTAL_OTHER_VISITOR_REVENUE while this model
--     dropped them and substituted a donation line legacy books elsewhere.
--  2. ECOM_GROSS_PROFIT symmetry. The budget side carried an
--     ECOM_GROSS_PROFIT row AND folded it into the budget
--     TOTAL_RETAIL_GROSS_PROFIT, while the actual side had neither, so the
--     variance on that composite compared unlike totals. The budget composite
--     now matches the actual composite (store + carts) and the actual side
--     emits an explicit typed-NULL ECOM_GROSS_PROFIT placeholder. Cause:
--     PENDING AN UPSTREAM ADDITION -- the measure is buildable from
--     CounterPoint facility 1234 sales less fact_cogs cost and is scheduled
--     for release 8.6.0 under the ADR-005 gate.
--
-- ADR-004: all business logic in dbt, never Power BI.
-- ADR-021: composites authored once; placeholders are typed NULLs with a cause.

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
           cast(total_retail_gross_profit_ex_cafe as number(38,4)), null, null from a_wide
    union all
    -- Both donation composites are governed semantic-view metrics; this model
    -- projects them rather than restating their components (ADR-021).
    select report_date, 'TOTAL_MEMORIAL_DONATIONS',
           cast(total_memorial_donations as number(38,4)), null, null from a_wide
    union all
    select report_date, 'TOTAL_MUSEUM_DONATIONS',
           cast(total_museum_donations as number(38,4)), null, null from a_wide
    union all
    -- Total Estimated Revenue is a governed semantic-view metric as of 8.1.0
    -- (it was authored inline here AND in rpt_tracker_powerbi). Component set
    -- is unchanged from the inline version except for the memorial-donation
    -- realignment described in the header.
    select report_date, 'TOTAL_ESTIMATED_REVENUE',
           cast(total_estimated_revenue as number(38,4)), null, null from a_wide
),

a_placeholder as (
    -- ECOM_GROSS_PROFIT actual: typed NULL, not zero and not omitted (ADR-021).
    -- Cause: PENDING AN UPSTREAM ADDITION. Both inputs are staged
    -- (int_counterpoint__retail_lines facility_group = 'ecommerce' for sales,
    -- its sale_cost for the fact_cogs equivalent); the measure is built in
    -- 8.6.0. Until then the ECOM_GROSS_PROFIT budget row has no actual
    -- counterpart, and this row makes that explicit and typed rather than
    -- an incidental NULL produced by the outer join.
    select report_date, 'ECOM_GROSS_PROFIT' as line_item_code,
           cast(null as number(38,4)) as amount,
           cast(null as number(38,4)) as numerator,
           cast(null as number(38,4)) as denominator
    from a_wide
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
    union all select report_date, line_item_code, amount, numerator, denominator from a_placeholder
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
    -- Total Tour Revenue (no virtual budget).
    select report_date, 'TOTAL_TOUR_REVENUE' as line_item_code,
           cast(revealed_tour_revenue + mem_mus_tour_revenue + mus_guided_tour_revenue
                + mem_guided_tour_revenue as number(38,4)) as amount,
           cast(null as number(38,4)) as numerator, cast(null as number(38,4)) as denominator from b_wide
    union all
    -- Total Retail GP: store + carts on BOTH scenarios. ecom_gross_profit is
    -- dropped from the budget composite because the actual composite has no
    -- ecom component to compare it against -- the variance column was
    -- differencing unlike totals. The ECOM_GROSS_PROFIT budget row itself is
    -- unchanged and still printed; only the composite changes. Both sides get
    -- ecom back in 8.6.0 when the actual measure exists.
    select report_date, 'TOTAL_RETAIL_GROSS_PROFIT',
           cast(mus_store_gross_profit + retail_carts_gross_profit as number(38,4)),
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