-- Test (business_rule): the Earned Income operating-expense feed still does not exist
-- Severity: warn — this is a standing reminder, not a regression. The Earned
-- Income Variance Report goes to the CFO with a whole section of it blank
-- because 911dw.fact_budgeted_expenses was fed by a hand-maintained workbook
-- (/opt/pentaho/budgets/BudgetedExpensesDailies.xlsx) that has no owner named
-- anywhere in the migrated estate and no platform equivalent. This test keeps
-- that fact in front of whoever runs the build, every build, until somebody
-- lands the feed.
--
-- PROMOTE TO ERROR: never. It goes SILENT by itself the moment
-- seed_budgeted_expense has rows — delete it at that point rather than promoting
-- it.
--
-- It fires on three distinct conditions, and the second and third are the ones
-- that would otherwise pass unnoticed:
--   1. The seed is empty (today's state).
--   2. The seed has rows but every operating-expense column on the fact is
--      still NULL — the seed loaded and the join did not, e.g. a key_date
--      format change.
--   3. The seed has rows and the fact has ZEROS where it should have NULLs —
--      somebody added a coalesce and turned "we do not know" into "it was
--      nothing", which on an expense line understates cost and overstates net
--      earned income. That is the exact failure mode this report cannot afford.

{{ config(severity='warn') }}

with seed_state as (
    select count(*) as seed_rows
    from {{ ref('seed_budgeted_expense') }}
),

fact_state as (
    select
        count(*)                                        as fact_rows,
        count(est_operating_expenses)                   as est_expense_non_null,
        count(total_operating_expenses)                 as total_expense_non_null,
        count(est_operating_expenses_budget)            as est_budget_non_null,
        count_if(est_operating_expenses = 0)            as est_expense_zero_filled,
        count_if(total_operating_expenses = 0)          as total_expense_zero_filled
    from {{ ref('fct_earned_income') }}
)

select
    'operating_expense_feed_has_no_source'              as failure,
    s.seed_rows,
    f.fact_rows,
    f.est_expense_non_null,
    'EST_OPERATING_EXPENSES and TOTAL_OPERATING_EXPENSES publish as typed NULL; 2 layout lines are Stub; no net earned income can be reported' as consequence
from seed_state s
cross join fact_state f
where s.seed_rows = 0

union all

select
    'expense_seed_has_rows_but_the_fact_does_not',
    s.seed_rows,
    f.fact_rows,
    f.est_expense_non_null,
    'seed_budgeted_expense loaded but every expense column on fct_earned_income is still NULL - check the key_date join in int_earned_income__line_items'
from seed_state s
cross join fact_state f
where s.seed_rows > 0
  and f.est_expense_non_null = 0
  and f.total_expense_non_null = 0
  and f.est_budget_non_null = 0

union all

select
    'expense_placeholder_has_been_zero_filled',
    s.seed_rows,
    f.fact_rows,
    f.est_expense_zero_filled + f.total_expense_zero_filled,
    'an expense column is 0 rather than NULL - a zero here asserts the expense was nothing, which understates cost on a CFO report (ADR-021 placeholder rule)'
from seed_state s
cross join fact_state f
where s.seed_rows = 0
  and (f.est_expense_zero_filled > 0 or f.total_expense_zero_filled > 0)
