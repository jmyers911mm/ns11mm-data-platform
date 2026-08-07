-- Marts report: Retail Performance period windows (the six printed period columns, defined ONCE)
-- ---------------------------------------------------------------------------
-- Domain: retail
-- Grain:  one row per period_code (six rows)
--
-- Single authored definition of the Retail Performance Report's printed
-- period columns — Current Day, Same Day Last Year, WTD, MTD, QTD, YTD — as
-- [start_date .. end_date] ranges anchored on the report's as-of date.
-- Consumed by rpt_retail_report_periods (page 1) and
-- rpt_retail_category_periods (page 2) so the two pages can never disagree
-- about what "MTD" means. Do not restate these windows in a consumer.
--
-- AS-OF ANCHOR: the latest ACTUALS date before today, taken from
-- rpt_retail_powerbi — NOT from rpt_retail_report_long, whose budget side
-- carries forward-dated forecast rows that would drag the anchor into the
-- future and inflate every budget window. Same convention as
-- rpt_retail_narrative_brief (max report_date < current_date).
--
-- Period definitions (validate against the legacy .prpt before sign-off):
--   CURRENT_DAY  the as-of date
--   SDLY         as-of minus 364 days — same weekday, matching dim_date's
--                anchor convention and the narrative brief's prior_year
--   WTD          Sunday-start week through as-of; mirrors dim_date's
--                first_day_of_week and is computed explicitly rather than via
--                date_trunc('week') so the session WEEK_START parameter
--                cannot change the answer
--   MTD/QTD/YTD  calendar month / quarter / year through as-of (calendar, not
--                fiscal — fiscal calendar is an open ADR-005 item)
--
-- ADR-018 note: rpt-from-rpt is the sanctioned projection-chain exception,
-- same as the report_long / narrative chains.
--
-- ADR-004: all business logic in dbt, never Power BI.

{{ config(materialized='view', grants={'select': ['POWERBI_ROLE']}) }}

with as_of as (
    select max(report_date) as as_of_date
    from {{ ref('rpt_retail_powerbi') }}
    where report_date < current_date()
)

select as_of_date, 'CURRENT_DAY' as period_code, 'Current Day' as period_label, 10 as period_sort,
       as_of_date as start_date, as_of_date as end_date
from as_of
union all
select as_of_date, 'SDLY', 'Same Day Last Year', 20,
       dateadd(day, -364, as_of_date), dateadd(day, -364, as_of_date)
from as_of
union all
select as_of_date, 'WTD', 'Week to Date', 30,
       dateadd(day, -1 * dayofweek(as_of_date), as_of_date), as_of_date
from as_of
union all
select as_of_date, 'MTD', 'Month to Date', 40,
       date_trunc('month', as_of_date)::date, as_of_date
from as_of
union all
select as_of_date, 'QTD', 'Quarter to Date', 50,
       date_trunc('quarter', as_of_date)::date, as_of_date
from as_of
union all
select as_of_date, 'YTD', 'Year to Date', 60,
       date_trunc('year', as_of_date)::date, as_of_date
from as_of
