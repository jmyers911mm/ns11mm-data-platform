-- =====================================================================
-- RETAIL_POWERBI  -  Power BI consumption view over the RETAIL semantic view
-- ---------------------------------------------------------------------
-- Twin of rpt_dpr_powerbi, for the Retail Performance Report.
--
-- Power BI's native Snowflake connector CANNOT browse a Snowflake
-- SEMANTIC VIEW object directly. The supported pattern is to wrap the
-- SEMANTIC_VIEW() query in a normal view and point Power BI at the view.
--
-- Every metric DEFINITION stays inside the RETAIL semantic view
-- (ADR-004: no business logic in Power BI). This wrapper is a thin,
-- day x facility projection - one row per (REPORT_DATE, KEY_FACILITY) -
-- that Power BI imports and slices by selling area (Museum Store,
-- Memorial Carts, Museum Cafe, E-commerce, Audio Guide) and period.
--
-- Only ADDITIVE facility rollups are selected. The report's ratios
-- (capture rate, conversion, average sale, revenue-per-visitor, profit
-- margin) are non-additive and are recomputed at the display grain from
-- summed numerator/denominator components -- see rpt_retail_report_long
-- (in SQL, per ADR-004) and the DAX measures in the build spec.
-- =====================================================================

-- models/marts/reports/rpt_retail_powerbi.sql
{{ config(materialized='view', grants={'select': ['POWERBI_ROLE']}) }}

select * from semantic_view(
    {{ source('retail_semantic', 'RETAIL') }}

    dimensions
        dim_date.report_date         as report_date,
        dim_date.year_number         as calendar_year,
        dim_date.quarter_of_year     as calendar_quarter,
        dim_date.month_name          as month_name,
        dim_date.day_of_week_name    as day_name,
        dim_date.is_weekend          as is_weekend,
        fct_retail_daily.key_facility          as key_facility,
        fct_retail_daily.area_name             as area_name,
        fct_retail_daily.area_group            as area_group,
        fct_retail_daily.is_commemoration_day  as is_commemoration_day

    metrics
        fct_retail_daily.total_retail_net_sales   as net_sales,
        fct_retail_daily.total_retail_net_profit  as net_profit,
        fct_retail_daily.total_retail_net_units   as net_units,
        fct_retail_daily.total_retail_donations   as donations,
        fct_retail_daily.total_transactions       as transactions,
        fct_retail_daily.total_visitors           as visitor_count,
        fct_retail_daily.total_ecom_orders        as ecom_orders
)