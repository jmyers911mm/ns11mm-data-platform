/*
  ml_donor_churn_features
  Sources: rpt_member_360 + silver_sf_crm
  STATUS: Awaiting RAW data. Logic migrated from POC — updated ref from fct_member_360 to rpt_member_360.
*/

{{ config(enabled=false,materialized='table', tags=['daily', 'non-critical']) }}

with member as (
    select contact_id, membership_type, membership_status, donor_tier,
           donation_total_ytd, total_ticket_spend, total_retail_spend,
           total_lifetime_value, email_opens, email_clicks,
           engagement_segment, last_interaction_date,
           datediff('day', last_ticket_date, current_date()) as days_since_last_visit
    from {{ ref('rpt_member_360') }}
    where donor_tier != 'Non-Donor'
),

crm as (
    select contact_id,
           date_trunc('month', created_at)::date            as cohort_month,
           membership_start_date, membership_end_date, last_donation_date,
           datediff('month', created_at, current_date())    as tenure_months,
           datediff('day', last_donation_date, current_date()) as days_since_last_donation
    from {{ ref('silver_sf_crm') }}
    where donation_total_ytd > 0
)

select
    m.contact_id, m.membership_type, m.membership_status, m.donor_tier,
    m.donation_total_ytd, m.days_since_last_visit, m.total_lifetime_value,
    m.email_opens, m.email_clicks,
    case when m.email_opens > 0 then m.email_clicks::float / m.email_opens else 0 end as email_ctr,
    m.engagement_segment,
    c.cohort_month, c.tenure_months, c.days_since_last_donation,
    case when c.tenure_months > 0
         then round(m.donation_total_ytd / c.tenure_months, 2) else 0
    end                                                    as donation_velocity_per_month,
    case
        when c.days_since_last_donation <= 90  then 'Recent'
        when c.days_since_last_donation <= 365 then 'Lapsing'
        else 'Lapsed'
    end                                                    as recency_segment,
    case when m.membership_status in ('Expired', 'Lapsed', 'Grace Period') then 1 else 0 end as is_churned,
    case
        when m.days_since_last_visit > 60 and m.membership_status = 'Active' then 1
        else 0
    end                                                    as churn_risk_flag,
    current_timestamp()                                    as _feature_computed_at
from member m
left join crm c on m.contact_id = c.contact_id
