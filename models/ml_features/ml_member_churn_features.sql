/*
  ml_member_churn_features
  Source: rpt_member_360
  STATUS: Awaiting RAW data. Logic migrated from POC — updated ref from fct_member_360 to rpt_member_360.
*/

{{ config(materialized='table', tags=['daily', 'non-critical']) }}

select
    m.contact_id, m.membership_type, m.membership_status, m.donor_tier,
    m.donation_total_ytd, m.total_ticket_spend, m.total_retail_spend,
    m.total_lifetime_value, m.email_opens, m.email_clicks,
    case when m.email_opens > 0 then m.email_clicks::float / m.email_opens else 0 end as email_click_through_rate,
    m.engagement_segment,
    datediff('day', m.last_interaction_date, current_date()) as days_since_last_interaction,
    datediff('day', m.last_ticket_date, current_date())      as days_since_last_visit,
    case
        when m.membership_status in ('Expired', 'Lapsed', 'Grace Period') then 1
        else 0
    end                                                    as is_churned,
    case
        when datediff('day', m.last_ticket_date, current_date()) > 60
         and m.membership_status = 'Active' then 1
        else 0
    end                                                    as churn_risk_flag,
    current_timestamp()                                    as _feature_computed_at
from {{ ref('rpt_member_360') }} m
