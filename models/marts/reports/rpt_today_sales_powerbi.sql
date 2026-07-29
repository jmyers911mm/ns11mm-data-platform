-- =====================================================================
-- TODAY_SALES_POWERBI  -  Power BI consumption view over the ATTENDANCE
-- semantic view (FCT_TODAY_SALES_HOURLY). Twin of rpt_dpr_powerbi / rpt_retail_powerbi.
-- ---------------------------------------------------------------------
-- One row per (REPORT_DATE, HOUR_OF_DAY, KEY_FACILITY). Additive intraday
-- measures only; ratios (average sale, average qty, conversion, capture)
-- recompute from summed components in rpt_today_sales_report_long (ADR-004).
--
-- SOURCE STATUS: FCT_TODAY_SALES_HOURLY reads the same-day CounterPoint feed
-- (stg_counterpoint__todays_retail). Store visitors / attendance / totes and
-- the Memorial-Cart 1/2/3 split are not in the feed yet -> those lines are
-- Stub in the seed. See the build spec.
-- =====================================================================

-- models/marts/reports/rpt_today_sales_powerbi.sql
{{ config(materialized='view', grants={'select': ['POWERBI_ROLE']}) }}

select * from semantic_view(
    {{ source('attendance_semantic', 'ATTENDANCE') }}

    dimensions
        dim_date.report_date                    as report_date,
        dim_date.day_of_week_name               as day_name,
        fct_today_sales_hourly.hour_of_day      as hour_of_day,
        fct_today_sales_hourly.key_facility     as key_facility,
        fct_today_sales_hourly.area_name        as area_name

    metrics
        fct_today_sales_hourly.total_today_sales        as sales,
        fct_today_sales_hourly.total_today_profit       as profit,
        fct_today_sales_hourly.total_today_units        as units,
        fct_today_sales_hourly.total_today_transactions as transactions
)