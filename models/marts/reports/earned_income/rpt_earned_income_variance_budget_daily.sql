-- Marts report: budget-vs-actual daily conform — day-grain Earned Income budget
-- ---------------------------------------------------------------------------
-- Domain: earned income / budget
-- Grain:  one row per report_date
--
-- The ONE actual-vs-budget seam for the Earned Income Variance Report. Column
-- names are aligned to fct_earned_income (the actuals) so the two unpivot
-- identically in rpt_earned_income_variance_report_long. Renaming, typed NULLs
-- and cross-domain joins only -- no measure is defined here (ADR-021, comparison
-- conform role).
--
-- REUSE, AND WHERE IT STOPS. rpt_dpr_budget_daily already conforms the DPR
-- budget and ten of this report's budget lines are the same column from the
-- same seed, so they are read from it rather than re-conformed:
--     museum_attendance, mus_guided_tours, mus_guided_tour_revenue,
--     mem_guided_tours, mem_guided_tour_revenue, mem_mus_tours,
--     mem_mus_tour_revenue, early_access_tours, early_access_tour_revenue,
--     youth_fam_tour_revenue
-- Five lines cannot come from it, because THE TWO REPORTS BUDGET FROM DIFFERENT
-- SEEDS. The legacy EIV takes tickets, revenue, service fees and both CityPASS
-- lines from 911dw.fact_forecasted_value_for_date (= SEED_FORECASTED_VALUE_FOR_DATE
-- -> fct_budget_admissions_forecasts); the legacy DPR takes its same-named
-- budget lines from fact_dpr_forecasts (= SEED_DPR_FORECASTS ->
-- fct_budget_dpr_forecasts), which is what rpt_dpr_budget_daily projects. They
-- are two different numbers for the same day and both are correct for their own
-- report. Sourcing this report from the DPR conform would silently restate the
-- CFO's budget. The seam is documented in NOTES.md section 4 and asserted by
-- assert_earned_income_budget_differs_from_dpr_budget.
--
-- One further line, youth_fam_tours (the COUNT), exists in
-- fct_budget_dpr_forecasts but is not projected by rpt_dpr_budget_daily, so it
-- is read from the fact directly.
--
-- Legacy lineage: the forecast halves of
-- t_fact_earned_income_variance_values_table, _revenue_table, _totals_table,
-- _avg_ticket, t_fact_guided_tours_earned_income_variance and
-- t_fact_citypass_c3_earned_income_variance.
--
-- NOTE: intentionally NOT populated on the budget side, because no legacy step
-- forecasts them: the C3 booklet cohort, the scan-change cohorts, and every
-- component-level column the actuals fact carries for auditability. Those are
-- absent from this model rather than NULL-filled -- only PRINTED lines conform.
--
-- ADR-004: all business logic in dbt, never Power BI.

{{ config(materialized='view') }}

with
-- ─────────────────────────────────────────────── the ten reused DPR lines
dpr_conform as (
    select
        report_date,
        museum_attendance                                                   as museum_attendance,
        museum_guided_tours                                                 as mus_guided_tours,
        mus_guided_tour_revenue                                             as mus_guided_tour_revenue,
        memorial_guided_tours                                               as mem_guided_tours,
        mem_guided_tour_revenue                                             as mem_guided_tour_revenue,
        mem_mus_tours                                                       as mem_mus_tours,
        mem_mus_tour_revenue                                                as mem_mus_tour_revenue,
        -- The DPR conform maps fct_budget_dpr_forecasts.early_access_tours and
        -- .early_access_tour_rev onto its own EARLY_ACCESS_TOUR_COUNT and
        -- REVEALED_TOUR_REVENUE line names. The underlying columns are the same
        -- two the legacy EIV forecasts as early-access tours and revenue, so the
        -- DPR's line naming is undone here rather than the fact being re-read.
        early_access_tour_count                                             as early_access_tours,
        revealed_tour_revenue                                               as early_access_tour_revenue,
        -- Likewise: the DPR prints youth_fam_tour_rev as VIRTUAL_YF_TOUR_REVENUE.
        virtual_yf_tour_revenue                                             as youth_fam_tour_revenue
    from {{ ref('rpt_dpr_budget_daily') }}
),

-- ─────────────────────────────────────────────── the five EIV-only lines
-- fct_budget_admissions_forecasts is facility-grained; the legacy EIV steps
-- group by key_date with no facility predicate, so this sums across facilities.
adm_budget as (
    select
        date_value                                                          as report_date,
        sum(tickets_sold)                                                   as tickets,
        sum(ticket_revenue)                                                 as ticket_revenue,
        sum(service_fees)                                                   as service_fees,
        sum(citypass_tickets)                                               as citypass_tickets,
        sum(citypass_revenue)                                               as citypass_revenue
    from {{ ref('fct_budget_admissions_forecasts') }}
    group by 1
),

-- ─────────────────────────────────────────────── the one unprojected DPR line
dpr_budget as (
    select
        date_value                                                          as report_date,
        youth_fam_tours                                                     as youth_fam_tours
    from {{ ref('fct_budget_dpr_forecasts') }}
),

-- ─────────────────────────────────────────────── the expense budget
-- The manual expense workbook carries actual and budget on the same row, so the
-- budget values physically live in fct_earned_income. They are read back out
-- here so rpt_earned_income_variance_report_long still has exactly ONE budget
-- source. Both are typed NULL until seed_budgeted_expense has rows.
expense_budget as (
    select
        date_value                                                          as report_date,
        est_operating_expenses_budget                                       as est_operating_expenses,
        total_operating_expenses_budget                                     as total_operating_expenses
    from {{ ref('fct_earned_income') }}
),

spine as (
    select report_date from dpr_conform
    union select report_date from adm_budget
    union select report_date from dpr_budget
    union select report_date from expense_budget
)

select
    s.report_date,

    -- attendance
    d.museum_attendance,

    -- admissions (SEED_FORECASTED_VALUE_FOR_DATE, not the DPR seed)
    a.tickets,
    a.ticket_revenue,
    a.service_fees,
    a.citypass_tickets,
    a.citypass_revenue,

    -- tours
    d.mus_guided_tours,
    d.mus_guided_tour_revenue,
    d.mem_guided_tours,
    d.mem_guided_tour_revenue,
    d.early_access_tours,
    d.early_access_tour_revenue,
    b.youth_fam_tours,
    d.youth_fam_tour_revenue,
    d.mem_mus_tours,
    d.mem_mus_tour_revenue,

    -- operating expenses (typed NULL until the workbook has an owner)
    e.est_operating_expenses,
    e.total_operating_expenses

from spine s
left join dpr_conform    d on s.report_date = d.report_date
left join adm_budget     a on s.report_date = a.report_date
left join dpr_budget     b on s.report_date = b.report_date
left join expense_budget e on s.report_date = e.report_date
