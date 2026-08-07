-- Marts report: Retail Performance period grid (as-of snapshot, one row per line item x period)
-- ---------------------------------------------------------------------------
-- Domain: retail
-- Grain:  one row per period_code x line_item_code
--
-- The Retail Performance Report's printed grid, resolved in SQL over
-- rpt_retail_report_long across the six windows from
-- rpt_retail_period_windows: one row per matrix cell-group with actual, goal
-- and variance already computed. Power BI renders the grid with NO time
-- intelligence — this is what makes the report viable in DirectQuery (the DAX
-- form issued one time-intelligence query per cell across ~600 cells).
--
-- Supersedes the "periods in DAX, never in SQL" instruction in the original
-- Retail build spec, which assumed Import mode. Ratio correctness is not lost
-- but enforced: ratio lines divide sum(numerator) / sum(denominator) WITHIN
-- each window — ratio-of-sums, never an average of daily ratios — so a ratio
-- is correct at Current Day and YTD alike. Additive lines sum. Variance is
-- blank-guarded so unbudgeted lines read NULL, never -100%.
--
-- AS-OF SNAPSHOT: emits only the current reporting day's grid (~34 line items
-- x 6 periods = ~204 rows), matching the report's "day of data" framing. For
-- history, read rpt_retail_report_long.
--
-- Line labels, section, order, indent, format and availability come from
-- dim_retail_line_item in Power BI (joined on line_item_code) — deliberately
-- not duplicated here.
--
-- ADR-018 note: rpt-from-rpt is the sanctioned projection-chain exception.
-- ADR-004: all business logic in dbt, never Power BI.

{{ config(materialized='view', grants={'select': ['POWERBI_ROLE']}) }}

with w as (
    select * from {{ ref('rpt_retail_period_windows') }}
),

-- Every long-model row assigned to each window it falls inside
rows_by_period as (
    select
        w.as_of_date,
        w.period_code,
        w.period_label,
        w.period_sort,
        l.line_item_code,
        l.key_facility,
        l.amount,
        l.numerator,
        l.denominator,
        l.budget_amount,
        l.budget_numerator,
        l.budget_denominator
    from w
    inner join {{ ref('rpt_retail_report_long') }} l
        on l.report_date between w.start_date and w.end_date
),

agg as (
    select
        as_of_date,
        period_code,
        period_label,
        period_sort,
        line_item_code,
        max(key_facility)          as key_facility,
        sum(amount)                as actual_amount,
        sum(numerator)             as actual_numerator,
        sum(denominator)           as actual_denominator,
        sum(budget_amount)         as budget_amount,
        sum(budget_numerator)      as budget_numerator,
        sum(budget_denominator)    as budget_denominator
    from rows_by_period
    group by 1, 2, 3, 4, 5
),

-- Resolve ratio-of-sums once, then reuse for variance (no repeated expressions)
resolved as (
    select
        a.*,
        coalesce(a.actual_amount, a.actual_numerator / nullif(a.actual_denominator, 0)) as actual_value,
        coalesce(a.budget_amount, a.budget_numerator / nullif(a.budget_denominator, 0)) as budget_value
    from agg a
)

select
    as_of_date,
    period_code,
    period_label,
    period_sort,
    line_item_code,
    key_facility,

    -- component sums retained for audit / reconciliation
    actual_amount,
    actual_numerator,
    actual_denominator,
    budget_amount,
    budget_numerator,
    budget_denominator,

    -- display values: additive sums, ratio lines as ratio-of-sums
    actual_value,
    budget_value,

    -- variance, blank-guarded (NULL budget -> NULL variance, not -100%)
    case when budget_value is null then null
         else actual_value - budget_value end                        as variance,
    case when budget_value is null then null
         else (actual_value - budget_value) / nullif(abs(budget_value), 0) end as variance_pct
from resolved
