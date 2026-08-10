-- Marts report: DPR MTD/YTD printed grid (ACTUAL / PRIOR YEAR / $ VAR / % VAR per printed row)
-- ---------------------------------------------------------------------------
-- Domain: DPR / cross-domain
-- Grain:  one row per period_group x print_code
--
-- The DPR "Month to Date" and "Year to Date" Excel variants, print-ready: one
-- row per printed line per period group, with the workbooks' four columns
-- resolved as columns here — actual, prior_year, variance_amount,
-- variance_pct. Both variants come from this one model (period_group = 'MTD'
-- or 'YTD'); the Power BI report is two pages, or one page with a slicer.
--
-- Ratio lines (capture rate, conversion rate, average sale) divide
-- sum(numerator) / sum(denominator) WITHIN each window, so an MTD or YTD ratio
-- is a ratio-of-sums, not an average of daily ratios. Additive lines sum.
--
-- Variance is blank-guarded: when prior_year is NULL the variance columns are
-- NULL rather than -100%. NOTE this differs from the legacy workbook, which
-- prints '0%' in several cells where the prior-year value is zero or missing
-- (e.g. Memorial Guided Tours, Mask Donations); NULL is the honest answer and
-- Power BI can display it as blank or as a dash.
--
-- Built as a cross join of period groups x printed lines LEFT joined to the
-- aggregated metrics, so every printed row renders even where its metric has
-- no source. Stub metric_codes with no row in rpt_dpr_mtd_ytd_long
-- (EARLY_ACCESS_TOUR_COUNT, YF_TOUR_COUNT, EA_MEM_MUS_TOUR_*,
-- REVEALED_TOUR_REVENUE_VIRTUAL, ECOM_GROSS_PROFIT,
-- BUDGETED_OPERATING_EXPENSES, REVENUE_PCT_OF_OPEX) come through NULL and are
-- marked 'Stub' in the seed.
--
-- ADR-018 note: rpt-from-rpt is the sanctioned projection-chain exception.
-- ADR-004: all business logic in dbt, never Power BI.

{{ config(materialized='view', grants={'select': ['POWERBI_ROLE']}) }}

with w as (
    select * from {{ ref('rpt_dpr_period_windows') }}
),

pl as (
    select * from {{ ref('dim_dpr_mtd_ytd_print_line') }}
),

-- Sum each metric inside each (period_group, scenario) window
agg as (
    select
        w.period_group,
        w.period_label,
        w.period_sort,
        w.scenario,
        l.metric_code,
        sum(l.amount)       as amount,
        sum(l.numerator)    as numerator,
        sum(l.denominator)  as denominator
    from w
    inner join {{ ref('rpt_dpr_mtd_ytd_long') }} l
        on l.report_date between w.start_date and w.end_date
    group by 1, 2, 3, 4, 5
),

-- Resolve additive vs ratio once per window
resolved as (
    select
        period_group,
        period_label,
        period_sort,
        scenario,
        metric_code,
        coalesce(amount, numerator / nullif(denominator, 0)) as value
    from agg
),

-- Pivot current vs prior into the workbooks' two value columns
pivoted as (
    select
        period_group,
        period_label,
        period_sort,
        metric_code,
        max(case when scenario = 'current' then value end) as actual,
        max(case when scenario = 'prior'   then value end) as prior_year
    from resolved
    group by 1, 2, 3, 4
),

-- Distinct period grid for the cross join (one row per period_group)
periods as (
    select distinct as_of_date, period_group, period_label, period_sort
    from w
)

select
    p.as_of_date,
    p.period_group,
    p.period_label,
    p.period_sort,

    pl.print_code,
    pl.print_order,
    pl.section,
    pl.section_sort_order,
    pl.line_item,
    pl.line_item_display,
    pl.indent,
    pl.format,
    pl.metric_code,
    pl.availability,

    v.actual,
    v.prior_year,
    case when v.prior_year is null then null
         else v.actual - v.prior_year end                        as variance_amount,
    case when v.prior_year is null then null
         else (v.actual - v.prior_year) / nullif(abs(v.prior_year), 0) end as variance_pct

from periods p
cross join pl
left join pivoted v
    on  v.period_group = p.period_group
    and v.metric_code  = pl.metric_code
