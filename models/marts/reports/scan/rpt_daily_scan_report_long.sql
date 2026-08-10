-- Marts report: long/unpivoted Daily Scan serving shape (actual + forecast + scanned per line item)
-- ---------------------------------------------------------------------------
-- Domain: attendance / scanning
-- Grain:  one row per report_date x segment_key x line_item_code
--
-- Tidy Daily Scan presentation: unpivots rpt_daily_scan_powerbi into one long
-- shape carrying the report's three additive measures as line items:
--   TICKETS_SOLD          -> Actual
--   FORECAST_TICKETS_SOLD -> Forecast (the DSR passes_budget, surfaced by the
--                            wrapper as forecast_tickets_sold)
--   PASSES_SCANNED        -> Scanned
-- Feeds the Power BI Daily Scan Summary-by-Sales-Channel grid. All three
-- measures are additive, so there are no numerator/denominator columns:
-- Variance %, % Used, and % of Market are DAX ratio-of-sums BETWEEN the
-- carried line items (e.g. % Used = sum Scanned / sum Sold) at any grain.
-- Segment labels/order come from seed_scan_market_segment upstream
-- (fct_daily_scan), already conformed on the wrapper as segment_name — no new
-- line-item seed for this report. Explicit union (not UNPIVOT) so segments
-- with a NULL forecast keep their Forecast row.
--
-- ADR-004: all business logic in dbt, never Power BI.

{{ config(materialized='view', grants={'select': ['POWERBI_ROLE']}) }}

with w as (
    select * from {{ ref('rpt_daily_scan_powerbi') }}
)

select
    report_date, segment_key, segment_name,
    'TICKETS_SOLD' as line_item_code,
    cast(tickets_sold as number(38,4)) as amount
from w

union all
select
    report_date, segment_key, segment_name,
    'FORECAST_TICKETS_SOLD' as line_item_code,
    cast(forecast_tickets_sold as number(38,4)) as amount
from w

union all
select
    report_date, segment_key, segment_name,
    'PASSES_SCANNED' as line_item_code,
    cast(passes_scanned as number(38,4)) as amount
from w
