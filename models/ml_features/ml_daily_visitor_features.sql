/*
  ml_daily_visitor_features
  Sources: fct_digital_ad_performance + fct_website_traffic + fct_daily_operations + fct_visitor_traffic + dim_date
  STATUS: Awaiting RAW data. Logic migrated from POC — updated refs.
*/

{{ config(materialized='table', tags=['daily', 'non-critical']) }}

with marketing_signals as (
    select report_date,
           sum(impressions) as total_ad_impressions, sum(clicks) as total_ad_clicks,
           sum(spend) as total_ad_spend, sum(conversions) as total_ad_conversions
    from {{ ref('fct_digital_ad_performance') }}
    group by report_date
),

web_signals as (
    select report_date,
           sum(sessions) as total_web_sessions, sum(new_users) as total_new_users,
           sum(conversions) as total_web_conversions, avg(avg_session_duration_seconds) as avg_session_duration
    from {{ ref('fct_website_traffic') }}
    group by report_date
),

daily_ops as (
    select visit_date, total_visitors as daily_visitors, valid_scans, rejected_scans,
           gates_active, ticket_transactions, ticket_revenue,
           div0(ticket_revenue, nullif(ticket_transactions, 0)) as avg_ticket_value,
           retail_transactions, retail_revenue,
           div0(retail_revenue, nullif(retail_transactions, 0)) as avg_basket_value,
           total_revenue
    from {{ ref('fct_daily_operations') }}
),

peak_hour as (
    select scan_date, max(visitors_admitted) as peak_hour_visitors,
           max(case when visitors_admitted = max(visitors_admitted) over (partition by scan_date)
                    then scan_hour end) as peak_hour
    from {{ ref('fct_visitor_traffic') }}
    group by scan_date
)

select
    d.visit_date, dd.day_of_week_name as day_of_week, dd.is_weekend, dd.is_commemoration_day,
    dd.month_of_year as month_num, dd.fiscal_year,
    d.daily_visitors, d.valid_scans, d.rejected_scans, d.gates_active,
    d.ticket_transactions, d.ticket_revenue, d.avg_ticket_value,
    d.retail_transactions, d.retail_revenue, d.avg_basket_value, d.total_revenue,
    ph.peak_hour, ph.peak_hour_visitors,
    coalesce(m.total_ad_impressions, 0) as total_ad_impressions,
    coalesce(m.total_ad_clicks, 0)      as total_ad_clicks,
    coalesce(m.total_ad_spend, 0)       as total_ad_spend,
    coalesce(w.total_web_sessions, 0)   as total_web_sessions,
    coalesce(w.total_new_users, 0)      as total_new_users,
    coalesce(w.total_web_conversions, 0) as total_web_conversions,
    current_timestamp()                 as _feature_computed_at
from daily_ops d
left join {{ ref('dim_date') }} dd on d.visit_date = dd.date_id
left join marketing_signals  m  on d.visit_date = m.report_date
left join web_signals        w  on d.visit_date = w.report_date
left join peak_hour          ph on d.visit_date = ph.scan_date
