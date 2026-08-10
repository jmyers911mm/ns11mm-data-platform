-- Marts report: Retail Performance printed grid (one row per printed line x period — PDF-faithful)
-- ---------------------------------------------------------------------------
-- Domain: retail
-- Grain:  one row per period_code x print_code
--
-- The Retail Performance Report exactly as printed: the legacy report puts
-- scenario on ROWS ('... Goal', '... Actual', and a shaded 'Variance' row on
-- selected metrics only), with the six periods as the only columns. This model
-- resolves each printed line to a SINGLE `value`, so Power BI needs one
-- measure, no scenario switch, no field parameter, and no time intelligence:
--   rows    = dim_retail_print_line (section -> line_item_display)
--   columns = period_label
--   values  = max(value)
--
-- Built as a cross join of the six windows x the 69 printed lines, LEFT joined
-- to the metric grid — so every printed row renders even where its metric has
-- no data (Medallion Machine has no facility mapping yet; E-commerce awaits
-- Shopify). Those are marked 'Stub' in the seed and come through NULL rather
-- than silently vanishing.
--
-- Supersedes nothing: rpt_retail_report_periods remains the metric-grain grid
-- (actual/goal/variance side by side) and is the audit surface for this model.
--
-- ADR-018 note: rpt-from-rpt is the sanctioned projection-chain exception.
-- ADR-004: all business logic in dbt, never Power BI.

{{ config(materialized='view', grants={'select': ['POWERBI_ROLE']}) }}

with w as (
    select distinct as_of_date, period_code, period_label, period_sort
    from {{ ref('rpt_retail_period_windows') }}
),

pl as (
    select * from {{ ref('dim_retail_print_line') }}
),

m as (
    select period_code, line_item_code, actual_value, budget_value, variance, variance_pct
    from {{ ref('rpt_retail_report_periods') }}
)

select
    w.as_of_date,
    w.period_code,
    w.period_label,
    w.period_sort,

    pl.print_code,
    pl.print_order,
    pl.section,
    pl.section_sort_order,
    pl.line_item,
    pl.line_item_display,
    pl.indent,
    pl.format,
    pl.scenario,
    pl.metric_code,
    pl.availability,

    -- the one number this printed row shows
    case pl.scenario
        when 'actual'   then m.actual_value
        when 'goal'     then m.budget_value
        when 'variance' then m.variance
    end                                     as value,

    -- carried for the variance rows' optional % display and for audit
    case when pl.scenario = 'variance' then m.variance_pct end as variance_pct

from w
cross join pl
left join m
    on  m.period_code    = w.period_code
    and m.line_item_code = pl.metric_code
