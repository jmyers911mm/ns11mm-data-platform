-- ML feature: visitor forecast training set for Snowflake ML FORECAST
-- ---------------------------------------------------------------------------
-- Domain: operations (ML)
-- Grain:  one row per visit_date, where total_visitors > 0
--
-- Shapes fct_daily_operations into the ds/y contract Snowflake ML FORECAST
-- expects: ds = visit_date timestamp, y = total_visitors, with day-of-week,
-- weekend flag, month, revenue, transactions, and gates_active as exogenous
-- features. Ordered by visit_date.
-- NOTE: total_revenue = ticket_revenue + retail_revenue, so it tracks ticket
-- revenue only until retail lands in fct_daily_operations.
--
-- ADR-004: all business logic lives here, not in Power BI.

{{ config(materialized='table', tags=['daily', 'non-critical']) }}

select
    visit_date::timestamp_ntz                              as ds,
    total_visitors                                         as y,
    day_of_week_name                                       as day_of_week,
    case when extract(dow from visit_date) in (0, 6) then 1 else 0 end as is_weekend,
    extract(month from visit_date)                         as month_num,
    ticket_revenue + retail_revenue                        as total_revenue,
    ticket_transactions,
    gates_active
from {{ ref('fct_daily_operations') }}
left join {{ ref('dim_date') }} dd on visit_date = dd.date_key
where total_visitors > 0
order by visit_date
