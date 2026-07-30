-- Marts report: budget-vs-actual daily serving — day x facility retail budget (goal)
-- ---------------------------------------------------------------------------
-- Domain: retail / budget
-- Grain:  one row per report_date x key_facility
--
-- Day x facility BUDGET (goal) for the Retail Performance Report, conformed
-- from fct_budget_retail_forecasts. Twin of rpt_dpr_budget_daily. Column
-- names are aligned to rpt_retail_powerbi (the actuals) so the two unpivot
-- IDENTICALLY. Feeds rpt_retail_report_long (the report's "... Goal" and
-- Variance rows) and rpt_retail_narrative_brief.
-- NOTE: the forecast carries BOTH the additive components (visitors,
-- customers, revenue, profit, donations, museum_attendance) AND the ratio
-- goals the PDF prints as-given (capture_rate, conversion_rate, average_sale).
-- Components are carried so goal ratios recompute from summed components at
-- any period grain (matching the actual-side ratio-of-sums rule); the
-- as-given goal ratios pass through too (..._goal_given) for verbatim lines.
-- net_units and ecom_orders have no budget source -> emitted NULL.
--
-- ADR-004: all business logic in dbt, never Power BI.

{{ config(materialized='view', grants={'select': ['POWERBI_ROLE']}) }}

with fc as (
    select
        date_value                          as report_date,
        key_facility,

        -- Additive components (names mirror rpt_retail_powerbi actuals)
        revenue                             as net_sales,
        profit_from_retail                  as net_profit,
        cast(null as number(38,4))          as net_units,          -- no budget source
        donations                           as donations,
        customers                           as transactions,        -- "Customers" goal
        visitors                            as visitor_count,        -- "Visitors" goal
        cast(null as number(38,4))          as ecom_orders,          -- no budget source
        museum_attendance                   as museum_attendance,    -- "Attendance Goal" context

        -- Ratio goals as printed on the PDF (optional verbatim display)
        capture_rate                        as capture_rate_goal_given,
        conversion_rate                     as conversion_rate_goal_given,
        average_sale                        as avg_sale_goal_given

    from {{ ref('fct_budget_retail_forecasts') }}
)

select * from fc
