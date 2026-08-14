-- Marts report: long/unpivoted Earned Income Variance serving shape (actual + budget per line item)
-- ---------------------------------------------------------------------------
-- Domain: earned income
-- Grain:  one row per report_date x line_item_code
--
-- Tidy Earned Income Variance presentation: unpivots fct_earned_income (actual)
-- and rpt_earned_income_variance_budget_daily (budget) into one long shape
-- carrying BOTH scenarios, with the two report composites and the one ratio
-- resolved here and only here. Feeds the Power BI Earned Income Variance matrix
-- (which joins dim_earned_income_line_item for section/label/order/format and
-- dim_date for the year axis) and rpt_earned_income_variance_narrative_brief.
--   amount / numerator / denominator                      -> ACTUAL
--   budget_amount / budget_numerator / budget_denominator -> BUDGET
--
-- VARIANCE IS NOT STORED. The legacy workbook prints a *_diff column beside
-- every actual/forecast pair (nineteen of them). Those columns are absent here
-- on purpose: variance is actual minus budget and variance percent is that
-- difference over budget, both computed at the display grain by one DAX measure
-- per scenario. Storing a day-grain difference would make the monthly and YTD
-- variance an average of daily differences on the ratio line, which is the
-- average-of-ratios artefact ADR-021 exists to prevent. The two scenarios are
-- carried; the subtraction happens once, at the grain the reader is looking at.
--
-- THE THIRTEEN SHEETS ARE NOT THIRTEEN SECTIONS. t_earned_income_variance_tabs
-- is a single query with `year(key_date) as year` routed to thirteen
-- TypeExitExcelWriterStep outputs; the sheets are calendar years 2014-2026 and
-- grow by one each January. They are a dim_date slicer here, not layout.
--
-- NOTE: no *_powerbi wrapper. ADR-021 makes the wrapper the only caller of
-- SEMANTIC_VIEW(), and 8.11.0 adds no EARNED_INCOME semantic view, so this shape
-- reads the mart fact directly -- the path rpt_carts_report_long and
-- rpt_retail_analysis_report_long already take. Nothing reads rightward.
--
-- NOTE: no *_period_windows model. The workbook prints day rows inside a year
-- sheet, not period columns, so there is no analogue and none was invented.
--
-- Legacy lineage: t_earned_income_variance_tabs over
-- 911dw.earned_income_report_analysis.
-- ADR-004: all business logic in dbt, never Power BI.

{{ config(materialized='view', grants={'select': ['POWERBI_ROLE']}) }}

{#- Additive printed lines. The actual fact and the budget conform expose      -#}
{#- IDENTICAL column names for every one of these, which is the whole point of -#}
{#- the conform: one list drives both legs and they cannot drift apart.        -#}
{#- Explicit UNION ALL rather than UNPIVOT: Snowflake's UNPIVOT drops NULL     -#}
{#- measures, and the Stub lines MUST render as present-and-blank rows.        -#}
{% set additive_lines = [
    'museum_attendance',
    'tickets',
    'ticket_revenue',
    'service_fees',
    'citypass_tickets',
    'citypass_revenue',
    'mus_guided_tours',
    'mus_guided_tour_revenue',
    'mem_guided_tours',
    'mem_guided_tour_revenue',
    'early_access_tours',
    'early_access_tour_revenue',
    'youth_fam_tours',
    'youth_fam_tour_revenue',
    'mem_mus_tours',
    'mem_mus_tour_revenue',
    'est_operating_expenses',
    'total_operating_expenses'
] %}

with
-- =========================================================== ACTUAL
actual_wide as (
    select
        date_value                                                          as report_date,
        cast(museum_attendance         as number(38, 4))                    as museum_attendance,
        cast(tickets                   as number(38, 4))                    as tickets,
        cast(ticket_revenue            as number(38, 4))                    as ticket_revenue,
        cast(service_fees              as number(38, 4))                    as service_fees,
        cast(citypass_tickets          as number(38, 4))                    as citypass_tickets,
        cast(citypass_revenue          as number(38, 4))                    as citypass_revenue,
        cast(mus_guided_tours          as number(38, 4))                    as mus_guided_tours,
        cast(mus_guided_tour_revenue   as number(38, 4))                    as mus_guided_tour_revenue,
        cast(mem_guided_tours          as number(38, 4))                    as mem_guided_tours,
        cast(mem_guided_tour_revenue   as number(38, 4))                    as mem_guided_tour_revenue,
        cast(early_access_tours        as number(38, 4))                    as early_access_tours,
        cast(early_access_tour_revenue as number(38, 4))                    as early_access_tour_revenue,
        cast(youth_fam_tours           as number(38, 4))                    as youth_fam_tours,
        cast(youth_fam_tour_revenue    as number(38, 4))                    as youth_fam_tour_revenue,
        cast(mem_mus_tours             as number(38, 4))                    as mem_mus_tours,
        cast(mem_mus_tour_revenue      as number(38, 4))                    as mem_mus_tour_revenue,
        cast(est_operating_expenses    as number(38, 4))                    as est_operating_expenses,
        cast(total_operating_expenses  as number(38, 4))                    as total_operating_expenses
    from {{ ref('fct_earned_income') }}
),

-- =========================================================== BUDGET
budget_wide as (
    select
        report_date,
        cast(museum_attendance         as number(38, 4))                    as museum_attendance,
        cast(tickets                   as number(38, 4))                    as tickets,
        cast(ticket_revenue            as number(38, 4))                    as ticket_revenue,
        cast(service_fees              as number(38, 4))                    as service_fees,
        cast(citypass_tickets          as number(38, 4))                    as citypass_tickets,
        cast(citypass_revenue          as number(38, 4))                    as citypass_revenue,
        cast(mus_guided_tours          as number(38, 4))                    as mus_guided_tours,
        cast(mus_guided_tour_revenue   as number(38, 4))                    as mus_guided_tour_revenue,
        cast(mem_guided_tours          as number(38, 4))                    as mem_guided_tours,
        cast(mem_guided_tour_revenue   as number(38, 4))                    as mem_guided_tour_revenue,
        cast(early_access_tours        as number(38, 4))                    as early_access_tours,
        cast(early_access_tour_revenue as number(38, 4))                    as early_access_tour_revenue,
        cast(youth_fam_tours           as number(38, 4))                    as youth_fam_tours,
        cast(youth_fam_tour_revenue    as number(38, 4))                    as youth_fam_tour_revenue,
        cast(mem_mus_tours             as number(38, 4))                    as mem_mus_tours,
        cast(mem_mus_tour_revenue      as number(38, 4))                    as mem_mus_tour_revenue,
        cast(est_operating_expenses    as number(38, 4))                    as est_operating_expenses,
        cast(total_operating_expenses  as number(38, 4))                    as total_operating_expenses
    from {{ ref('rpt_earned_income_variance_budget_daily') }}
),

-- =========================================================== ACTUAL long
actual_long as (
    {% for col in additive_lines %}
    select
        report_date,
        '{{ col | upper }}'                                                 as line_item_code,
        {{ col }}                                                           as amount,
        cast(null as number(38, 4))                                         as numerator,
        cast(null as number(38, 4))                                         as denominator
    from actual_wide
    union all
    {% endfor %}

    -- Composite 1: Total Tickets Sold. Legacy
    -- t_fact_earned_income_variance_totals_table defines it as
    -- earned_revenue_report_values.total_tickets, which is the same union the
    -- Tickets and CityPASS Tickets lines are built from. Summing the two carried
    -- lines is that definition, authored once, here.
    select
        report_date,
        'TOTAL_TICKETS_SOLD'                                                as line_item_code,
        tickets + citypass_tickets                                          as amount,
        cast(null as number(38, 4)),
        cast(null as number(38, 4))
    from actual_wide

    union all

    -- Composite 2: Total Admissions Revenue. Legacy, verbatim:
    --   sum(actual_revenue + citypass_revenue + service_fees)
    select
        report_date,
        'TOTAL_ADMISSIONS_REVENUE'                                          as line_item_code,
        ticket_revenue + citypass_revenue + service_fees                    as amount,
        cast(null as number(38, 4)),
        cast(null as number(38, 4))
    from actual_wide

    union all

    -- The one ratio. Legacy t_fact_earned_income_variance_avg_ticket stores
    --   sum(actual_revenue) / sum(actual_tickets)
    -- as a day-grain column and then SUMs that column across days, which is an
    -- average of ratios. Components are carried instead and divided once at
    -- display grain (ADR-021 ratio rule).
    select
        report_date,
        'AVG_TICKET_PRICE'                                                  as line_item_code,
        cast(null as number(38, 4))                                         as amount,
        ticket_revenue                                                      as numerator,
        tickets                                                             as denominator
    from actual_wide
),

-- =========================================================== BUDGET long
budget_long as (
    {% for col in additive_lines %}
    select
        report_date,
        '{{ col | upper }}'                                                 as line_item_code,
        {{ col }}                                                           as budget_amount,
        cast(null as number(38, 4))                                         as budget_numerator,
        cast(null as number(38, 4))                                         as budget_denominator
    from budget_wide
    union all
    {% endfor %}

    -- Legacy budget composites, from the same seed the budget lines come from:
    --   forecasted_total_tickets    = tickets_sold + citypass_tickets
    --   forecasted_total_admissions = revenue + citypass_revenue + service_fees
    select
        report_date,
        'TOTAL_TICKETS_SOLD'                                                as line_item_code,
        tickets + citypass_tickets                                          as budget_amount,
        cast(null as number(38, 4)),
        cast(null as number(38, 4))
    from budget_wide

    union all

    select
        report_date,
        'TOTAL_ADMISSIONS_REVENUE'                                          as line_item_code,
        ticket_revenue + citypass_revenue + service_fees                    as budget_amount,
        cast(null as number(38, 4)),
        cast(null as number(38, 4))
    from budget_wide

    union all

    select
        report_date,
        'AVG_TICKET_PRICE'                                                  as line_item_code,
        cast(null as number(38, 4))                                         as budget_amount,
        ticket_revenue                                                      as budget_numerator,
        tickets                                                             as budget_denominator
    from budget_wide
)

-- =========================================================== MERGE
select
    coalesce(a.report_date, b.report_date)                                  as report_date,
    coalesce(a.line_item_code, b.line_item_code)                            as line_item_code,
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
