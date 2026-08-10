-- Marts report: DPR MTD/YTD period windows (four windows, defined ONCE)
-- ---------------------------------------------------------------------------
-- Domain: DPR
-- Grain:  one row per period_group x scenario (four rows)
--
-- Single authored definition of the DPR MTD and YTD workbooks' comparison
-- windows: current month-to-date and year-to-date, each paired with its PRIOR
-- YEAR counterpart, as [start_date .. end_date] ranges anchored on the
-- report's as-of date. Consumed by rpt_dpr_mtd_ytd_print.
--
-- PRIOR YEAR IS A CALENDAR-YEAR SHIFT, NOT -364 DAYS. This deliberately
-- differs from the daily DPR / Retail reports, whose "Same Day Last Year" is
-- as-of minus 364 days (same weekday). A 52-week shift is wrong for a
-- period-to-date comparison: 364 days before 2025-12-31 is 2025-01-01, i.e.
-- still the same calendar year, which would make "prior-year YTD" a one-day
-- window. MTD/YTD are calendar-aligned, so prior year = dateadd(year, -1)
-- and the window runs from that date's month/year start. Confirm against the
-- legacy .prpt before sign-off.
--
-- AS-OF ANCHOR: latest actuals date before today from rpt_dpr_powerbi. Accepts
-- an optional `dpr_as_of_date` var to pin the anchor for reconciliation:
--   dbt build --select rpt_dpr_period_windows+ \
--     --vars '{dpr_as_of_date: "2025-12-31"}'
--
-- ADR-018 note: rpt-from-rpt is the sanctioned projection-chain exception.
-- ADR-004: all business logic in dbt, never Power BI.

{{ config(materialized='view', grants={'select': ['POWERBI_ROLE']}) }}

{% set pinned_as_of = var('dpr_as_of_date', none) %}

with as_of as (
{% if pinned_as_of %}
    select '{{ pinned_as_of }}'::date as as_of_date
{% else %}
    select max(report_date) as as_of_date
    from {{ ref('rpt_dpr_powerbi') }}
    where report_date < current_date()
{% endif %}
),

anchors as (
    select
        as_of_date,
        dateadd(year, -1, as_of_date) as as_of_prior
    from as_of
)

select as_of_date, 'MTD' as period_group, 'Month to Date' as period_label, 10 as period_sort,
       'current' as scenario,
       date_trunc('month', as_of_date)::date as start_date, as_of_date as end_date
from anchors
union all
select as_of_date, 'MTD', 'Month to Date', 10,
       'prior',
       date_trunc('month', as_of_prior)::date, as_of_prior
from anchors
union all
select as_of_date, 'YTD', 'Year to Date', 20,
       'current',
       date_trunc('year', as_of_date)::date, as_of_date
from anchors
union all
select as_of_date, 'YTD', 'Year to Date', 20,
       'prior',
       date_trunc('year', as_of_prior)::date, as_of_prior
from anchors
