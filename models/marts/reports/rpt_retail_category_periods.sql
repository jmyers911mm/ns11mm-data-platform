-- Marts report: Retail Performance category period grid (page 2 as-of snapshot)
-- ---------------------------------------------------------------------------
-- Domain: retail
-- Grain:  one row per period_code x key_facility x category_code
--
-- Page 2 of the Retail Performance Report (Total Units / Total Profit per
-- product category) resolved across the same six windows as page 1, from
-- rpt_retail_period_windows — so the two pages can never disagree about what
-- a period means. Every measure here is additive, so this is a straight sum
-- per window; it exists so page 2 also renders with NO time intelligence
-- under DirectQuery.
--
-- Category budget stays NULL BY DESIGN: the retail forecast is facility-grain
-- (7.9.0 removed the wrong-grain join that repeated a facility budget on
-- every category row). The columns are carried so the seam is visible and
-- lights up if a category-grain forecast ever lands.
--
-- AS-OF SNAPSHOT: current reporting day only. For history, read
-- rpt_retail_category_long.
--
-- ADR-018 note: rpt-from-rpt is the sanctioned projection-chain exception.
-- ADR-004: all business logic in dbt, never Power BI.

{{ config(materialized='view', grants={'select': ['POWERBI_ROLE']}) }}

with w as (
    select * from {{ ref('rpt_retail_period_windows') }}
),

rows_by_period as (
    select
        w.as_of_date,
        w.period_code,
        w.period_label,
        w.period_sort,
        c.key_facility,
        c.area_name,
        c.area_group,
        c.category_code,
        c.net_units,
        c.net_profit,
        c.net_sales,
        c.donations,
        c.net_sales_budget,
        c.net_profit_budget
    from w
    inner join {{ ref('rpt_retail_category_long') }} c
        on c.report_date between w.start_date and w.end_date
)

select
    as_of_date,
    period_code,
    period_label,
    period_sort,
    key_facility,
    area_name,
    area_group,
    category_code,
    sum(net_units)          as net_units,
    sum(net_profit)         as net_profit,
    sum(net_sales)          as net_sales,
    sum(donations)          as donations,
    -- NULL by design at category grain (facility-grain forecast); seam kept open
    sum(net_sales_budget)   as net_sales_budget,
    sum(net_profit_budget)  as net_profit_budget
from rows_by_period
group by 1, 2, 3, 4, 5, 6, 7, 8
