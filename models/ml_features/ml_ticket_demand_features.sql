-- Rename fiscal_year to year for simplified calendar dimensions
-- Co-authored with CoCo
-- ML feature table: ticket demand features for Snowflake ML FORECAST
-- ---------------------------------------------------------------------------
-- Domain: admissions / ticketing (ML)
-- Grain:  one row per entry_date (visit_date) + ticket_type
--
-- Aggregates fct_ticket_availability to a daily per-type training row and adds
-- calendar attributes (from dim_date) plus lag (1d, 7d) and rolling (7d/30d avg,
-- 30d stddev) features on daily_reserved. Transient table, tagged daily /
-- non-critical.
-- NOTE: daily_reserved is surfaced as daily_visitors for FORECAST target naming.
-- Carries the upstream proxy-capacity caveat.
--
-- ADR-004: feature logic lives here, not in Power BI.

{{ config(materialized='table', transient=true, tags=['daily', 'non-critical']) }}

with daily_demand as (
    select entry_date, ticket_type,
           sum(tickets_reserved)    as daily_reserved,
           sum(ticket_capacity)     as daily_capacity,
           round(sum(tickets_reserved)::float / nullif(sum(ticket_capacity),0) * 100, 2) as daily_utilization_pct,
           count(case when demand_level = 'Sold Out'                       then 1 end) as windows_sold_out,
           count(case when demand_level in ('Sold Out','High Demand')      then 1 end) as windows_high_demand,
           count(*)                 as total_windows
    from {{ ref('fct_ticket_availability') }}
    group by entry_date, ticket_type
),

with_features as (
    select d.*, dd.day_of_week as day_of_week_num, dd.day_of_week_name as day_name,
           dd.is_weekend, dd.month_of_year as month_num, dd.year_number as year,
           lag(d.daily_reserved, 1) over (partition by d.ticket_type order by d.entry_date) as reserved_lag_1d,
           lag(d.daily_reserved, 7) over (partition by d.ticket_type order by d.entry_date) as reserved_lag_7d,
           avg(d.daily_reserved) over (partition by d.ticket_type order by d.entry_date rows between 6 preceding and current row) as reserved_7d_avg,
           avg(d.daily_reserved) over (partition by d.ticket_type order by d.entry_date rows between 29 preceding and current row) as reserved_30d_avg,
           stddev(d.daily_reserved) over (partition by d.ticket_type order by d.entry_date rows between 29 preceding and current row) as reserved_30d_stddev
    from daily_demand d
    left join {{ ref('dim_date') }} dd on d.entry_date = dd.date_key
)

select
    entry_date as visit_date,
    ticket_type,
    daily_reserved as daily_visitors,
    daily_capacity,
    daily_utilization_pct,
    windows_sold_out,
    windows_high_demand,
    total_windows,
    day_of_week_num,
    day_name,
    is_weekend,
    month_num,
    year,
    reserved_lag_1d,
    reserved_lag_7d,
    reserved_7d_avg,
    reserved_30d_avg,
    reserved_30d_stddev,
    current_timestamp() as _feature_computed_at
from with_features
