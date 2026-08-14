-- Test (reconciliation): the Earned Income budget and the DPR budget are two different numbers, and the difference stays visible
-- Severity: warn — this test does NOT assert a defect. It asserts that a known,
-- deliberate seam is still there, and it prints the size of it every build.
--
-- The Earned Income Variance Report and the Daily Performance Report both print
-- a budget for tickets and for ticket revenue, and they take them from DIFFERENT
-- SEEDS:
--     Earned Income : 911dw.fact_forecasted_value_for_date
--                     -> SEED_FORECASTED_VALUE_FOR_DATE
--                     -> fct_budget_admissions_forecasts   (facility-grained)
--     DPR           : 911dw.fact_dpr_forecasts
--                     -> SEED_DPR_FORECASTS
--                     -> fct_budget_dpr_forecasts          (day-grained)
-- Both are correct for their own report. Neither is derivable from the other.
-- rpt_earned_income_variance_budget_daily therefore reads
-- fct_budget_admissions_forecasts for those five lines instead of taking them
-- from rpt_dpr_budget_daily, even though it reuses ten other lines from it.
--
-- Two things this catches:
--   1. Somebody "tidies" the conform by sourcing everything from
--      rpt_dpr_budget_daily. The two columns become equal on every day and the
--      CFO's budget silently becomes the DPR's. divergent_days drops to zero and
--      this test fires.
--   2. The two seeds drift far apart. A structural gap (one seed loaded for a
--      period the other is not) shows up as a run of days where one side is null
--      or zero. That is a data-loading problem in the budget seeds, not a model
--      problem, and finance should know about it before the variance is read.
--
-- PROMOTE TO ERROR: never. This is a monitor. If the institution decides the two
-- reports should share one admissions budget, that is an ADR-005 decision; when
-- it is made, delete this test in the same release that makes the two seeds one.

{{ config(severity='warn') }}

with eiv as (
    select
        report_date,
        tickets                                                     as eiv_tickets,
        ticket_revenue                                              as eiv_ticket_revenue
    from {{ ref('rpt_earned_income_variance_budget_daily') }}
),

dpr as (
    select
        report_date,
        tickets_sold                                                as dpr_tickets,
        ticket_revenue                                              as dpr_ticket_revenue
    from {{ ref('rpt_dpr_budget_daily') }}
),

joined as (
    select
        e.report_date,
        e.eiv_tickets,
        d.dpr_tickets,
        e.eiv_ticket_revenue,
        d.dpr_ticket_revenue
    from eiv e
    inner join dpr d on e.report_date = d.report_date
),

summary as (
    select
        count(*)                                                                    as overlapping_days,
        count_if(abs(coalesce(eiv_tickets, 0) - coalesce(dpr_tickets, 0)) > 0.01)   as ticket_divergent_days,
        count_if(abs(coalesce(eiv_ticket_revenue, 0)
                     - coalesce(dpr_ticket_revenue, 0)) > 0.01)                     as revenue_divergent_days,
        sum(coalesce(eiv_ticket_revenue, 0) - coalesce(dpr_ticket_revenue, 0))      as revenue_budget_gap,
        count_if(eiv_tickets is null)                                               as eiv_days_with_no_budget,
        count_if(dpr_tickets is null)                                               as dpr_days_with_no_budget
    from joined
)

-- Failure 1: the seam has collapsed. Two independently-seeded budgets agreeing
-- to the cent on every overlapping day means somebody re-pointed one of them.
select
    'earned_income_budget_now_identical_to_dpr_budget'  as failure,
    overlapping_days,
    ticket_divergent_days,
    revenue_divergent_days,
    revenue_budget_gap
from summary
where overlapping_days > 30
  and ticket_divergent_days = 0
  and revenue_divergent_days = 0

union all

-- Failure 2: one of the two budget seeds has a coverage hole over a period the
-- other covers. Reported so finance sees it as a loading gap, not as variance.
select
    'a_budget_seed_has_a_coverage_hole',
    overlapping_days,
    eiv_days_with_no_budget,
    dpr_days_with_no_budget,
    revenue_budget_gap
from summary
where eiv_days_with_no_budget > 0
   or dpr_days_with_no_budget > 0
