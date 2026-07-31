-- Marts report: thin SEMANTIC_VIEW() projection of the ATTENDANCE semantic view for Power BI (Today's Sales)
-- ---------------------------------------------------------------------------
-- Domain: retail (intraday)
-- Grain:  one row per report_date x hour_of_day x key_facility
--
-- Thin intraday wrapper over the MARTS.ATTENDANCE semantic view's
-- FCT_TODAY_SALES_HOURLY metrics (Power BI cannot browse a SEMANTIC VIEW
-- object, so the SEMANTIC_VIEW() query is wrapped in a normal view). Additive
-- measures only. Feeds the Power BI Today's Sales report dataset.
-- NOTE: ratios (average sale, average qty, conversion, capture) recompute
-- from summed components at the display grain.
-- STATUS: FCT_TODAY_SALES_HOURLY reads the same-day CounterPoint feed
-- (stg_counterpoint__todays_retail); store visitors / attendance / totes and
-- the Memorial-Cart 1/2/3 split are not in the feed yet — Stub in the seed.
--
-- ADR-004: all business logic in dbt / the semantic view, never Power BI.

{{ config(materialized='view', grants={'select': ['POWERBI_ROLE']}) }}

select * from semantic_view(
    {{ source('attendance_semantic', 'ATTENDANCE') }}

    dimensions
        dt.report_date                    as report_date,
        dt.day_of_week_name               as day_name,
        ts.hour_of_day                    as hour_of_day,
        ts.key_facility                   as key_facility,
        ts.area_name                      as area_name

    metrics
        ts.total_today_sales              as sales,
        ts.total_today_profit             as profit,
        ts.total_today_units              as units,
        ts.total_today_transactions       as transactions
)