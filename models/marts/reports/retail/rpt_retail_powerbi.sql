-- Marts report: thin SEMANTIC_VIEW() projection of the RETAIL semantic view for Power BI
-- ---------------------------------------------------------------------------
-- Domain: retail
-- Grain:  one row per report_date x key_facility
--
-- Thin day x facility wrapper over the MARTS.RETAIL semantic view (Power BI
-- cannot browse a SEMANTIC VIEW object, so the SEMANTIC_VIEW() query is
-- wrapped in a normal view). Metric definitions stay in the semantic view;
-- only ADDITIVE facility rollups are selected. Feeds the Power BI Retail
-- Performance Report dataset, rpt_retail_report_long, and rpt_retail_narrative_brief.
-- NOTE: the report's ratios (capture rate, conversion, average sale,
-- revenue-per-visitor, profit margin) are non-additive and recompute at the
-- display grain from summed components — see rpt_retail_report_long.
--
-- ADR-004: all business logic in dbt / the semantic view, never Power BI.

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
        fct_retail_daily.total_retail_donation_ask as donations,
        fct_retail_daily.total_transactions       as transactions,
        fct_retail_daily.total_visitors           as visitor_count,
        fct_retail_daily.total_ecom_orders        as ecom_orders
)