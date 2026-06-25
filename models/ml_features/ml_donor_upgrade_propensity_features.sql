/*
  ml_donor_upgrade_propensity_features
  Sources: dim_customer + rpt_customer_ltv + silver_sf_marketing_cloud + fct_donor_retention
  STATUS: Awaiting RAW data. Logic migrated from POC — updated refs.
  Scores Known Members for likelihood to upgrade membership tier or increase giving.
*/

{{ config(materialized='table', tags=['daily', 'non-critical']) }}

with customer_base as (
    select customer_id, customer_segment, membership_type, membership_status,
           primary_email, email_count, phone_count
    from {{ ref('dim_customer') }}
    where customer_segment = 'Known Member'
),

spending as (
    select customer_id, total_ticket_spend, total_retail_spend, total_lifetime_value,
           ltv_tier, ticket_visits, retail_visits, first_transaction_date,
           last_transaction_date, avg_ticket_spend_per_visit, avg_retail_spend_per_visit
    from {{ ref('rpt_customer_ltv') }}
),

email_engagement as (
    select email_address,
           count(distinct case when event_type = 'Open'  then campaign_id end) as email_opens,
           count(distinct case when event_type = 'Click' then campaign_id end) as email_clicks,
           count(distinct case when event_type = 'Sent'  then campaign_id end) as emails_received,
           div0(count(distinct case when event_type = 'Open' then campaign_id end)::float,
                count(distinct case when event_type = 'Sent' then campaign_id end)) as open_rate
    from {{ ref('silver_sf_marketing_cloud') }}
    group by email_address
)

select
    c.customer_id, c.membership_type, c.membership_status,
    s.total_ticket_spend, s.total_retail_spend, s.total_lifetime_value,
    s.ltv_tier, s.ticket_visits, s.retail_visits,
    s.avg_ticket_spend_per_visit, s.avg_retail_spend_per_visit,
    coalesce(ee.email_opens, 0)                            as email_opens,
    coalesce(ee.email_clicks, 0)                           as email_clicks,
    coalesce(ee.open_rate, 0)                              as email_open_rate,
    datediff('day', s.last_transaction_date, current_date()) as days_since_last_transaction,
    datediff('day', s.first_transaction_date, current_date()) as customer_tenure_days,
    case
        when s.total_lifetime_value >= 500
         and coalesce(ee.open_rate, 0) >= 0.3
         and datediff('day', s.last_transaction_date, current_date()) <= 90 then 'High Propensity'
        when s.total_lifetime_value >= 100
         and coalesce(ee.open_rate, 0) >= 0.1 then 'Medium Propensity'
        else 'Low Propensity'
    end                                                    as upgrade_propensity_tier,
    current_timestamp()                                    as _feature_computed_at
from customer_base c
left join spending        s  on c.customer_id    = s.customer_id
left join email_engagement ee on c.primary_email  = ee.email_address
