-- models/marts/reports/rpt_retail_budget_daily.sql
-- Day x facility BUDGET (goal) for the Retail Performance Report, conformed
-- from FCT_BUDGET_RETAIL_FORECASTS. Twin of rpt_dpr_budget_daily.
--
-- Column names are aligned to rpt_retail_powerbi (the actuals) so the two
-- unpivot IDENTICALLY in rpt_retail_report_long -- the report's "... Goal"
-- rows and the Variance rows come from this. One row per (report_date, key_facility).
--
-- The forecast seed carries BOTH the additive components (visitors, customers,
-- revenue, profit, donations, museum_attendance) AND the ratio goals the PDF
-- prints as-given (capture_rate, conversion_rate, average_sale). We carry the
-- components so the goal ratios recompute from summed components at any period
-- grain (matching the actual-side ratio-of-sums rule); the as-given goal ratios
-- are passed through too (…_goal_given) for lines the business wants shown verbatim.
--
-- net_units and ecom_orders have no budget source -> emitted NULL (intentional gap).

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

    from {{ source('retail_budget', 'fct_budget_retail_forecasts') }}
)

select * from fc
