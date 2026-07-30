-- Rename fiscal_year to year for simplified calendar dimensions
/*
  fct_campaign_attribution
  Sources: fct_ad_campaign_daily + bridge_session_customer + fct_ticket_sales + fct_retail_line_items
  STATUS: Awaiting RAW data. Logic migrated from POC.
*/

{{ config(enabled=false,materialized='table', cluster_by=['report_date', 'channel_grouping']) }}

with campaign_spend as (
    select report_date, ad_platform, campaign_id, campaign_name, campaign_category,
           sum(impressions) as impressions, sum(clicks) as clicks, sum(spend) as spend
    from {{ ref('fct_ad_campaign_daily') }}
    group by report_date, ad_platform, campaign_id, campaign_name, campaign_category
),
attributed_sessions as (
    select session_date, channel_grouping, source, medium, customer_id, customer_segment, membership_type
    from {{ ref('bridge_session_customer') }}
    where matched_to_customer = true
),
attributed_ticket as (
    select ts.transaction_date, bsc.channel_grouping, bsc.source, bsc.medium,
           bsc.customer_segment, bsc.membership_type,
           count(distinct ts.transaction_id) as attributed_ticket_transactions,
           sum(ts.quantity) as attributed_tickets_sold,
           sum(ts.total_amount) as attributed_ticket_revenue
    from {{ ref('fct_ticket_sales') }} ts
    inner join attributed_sessions bsc
        on ts.customer_id = bsc.customer_id and ts.transaction_date = bsc.session_date
    group by ts.transaction_date, bsc.channel_grouping, bsc.source, bsc.medium, bsc.customer_segment, bsc.membership_type
),
attributed_retail as (
    select r.transaction_date, bsc.channel_grouping, bsc.source, bsc.medium,
           bsc.customer_segment, bsc.membership_type,
           count(distinct r.transaction_id) as attributed_retail_transactions,
           sum(r.total_amount) as attributed_retail_revenue
    from {{ ref('fct_retail_line_items') }} r
    inner join attributed_sessions bsc
        on r.customer_id = bsc.customer_id and r.transaction_date = bsc.session_date
    group by r.transaction_date, bsc.channel_grouping, bsc.source, bsc.medium, bsc.customer_segment, bsc.membership_type
)

select
    coalesce(t.transaction_date, r.transaction_date) as report_date,
    dd.year_number as year, dd.month_name, dd.is_weekend,
    coalesce(t.channel_grouping, r.channel_grouping) as channel_grouping,
    coalesce(t.source, r.source) as source,
    coalesce(t.medium, r.medium) as medium,
    coalesce(t.customer_segment, r.customer_segment) as customer_segment,
    coalesce(t.membership_type, r.membership_type) as membership_type,
    coalesce(t.attributed_ticket_transactions, 0) as attributed_ticket_transactions,
    coalesce(t.attributed_tickets_sold, 0) as attributed_tickets_sold,
    coalesce(t.attributed_ticket_revenue, 0) as attributed_ticket_revenue,
    coalesce(r.attributed_retail_transactions, 0) as attributed_retail_transactions,
    coalesce(r.attributed_retail_revenue, 0) as attributed_retail_revenue,
    coalesce(t.attributed_ticket_revenue, 0) + coalesce(r.attributed_retail_revenue, 0) as total_attributed_revenue,
    current_timestamp() as _loaded_at
from attributed_ticket t
full outer join attributed_retail r
    on t.transaction_date = r.transaction_date
    and t.channel_grouping = r.channel_grouping
    and t.source = r.source
    and t.medium = r.medium
left join {{ ref('dim_date') }} dd
    on coalesce(t.transaction_date, r.transaction_date) = dd.date_id
