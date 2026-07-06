/*
  rpt_member_360
  Sources: dim_customer + fct_ticket_sales + fct_retail_line_items + fct_fundraising + silver_sf_marketing_cloud
  STATUS: Awaiting RAW data. Logic migrated from POC. Added Classy donations.
*/

{{ config(enabled=false,materialized='table') }}

with ticket_agg as (
    select
        customer_id,
        count(distinct transaction_id)  as ticket_purchase_count,
        sum(total_amount)               as total_ticket_spend,
        sum(quantity)                   as tickets_bought,
        max(transaction_date)           as last_ticket_date
    from {{ ref('fct_ticket_sales') }}
    where customer_id is not null
    group by customer_id
),

retail_agg as (
    select
        customer_id,
        count(distinct transaction_id)  as retail_purchase_count,
        sum(total_amount)               as total_retail_spend,
        sum(quantity)                   as retail_items_bought,
        max(transaction_date)           as last_retail_date
    from {{ ref('fct_retail_line_items') }}
    where customer_id is not null
    group by customer_id
),

donation_agg as (
    select
        donor_member_id                 as customer_id,
        count(distinct transaction_id)  as donation_count,
        sum(gross_amount)               as total_donations,
        max(transaction_date)           as last_donation_date
    from {{ ref('fct_fundraising') }}
    where donor_member_id is not null
    group by donor_member_id
),

email_agg as (
    select
        email_address,
        count(distinct case when event_type = 'Open'  then campaign_id end) as email_opens,
        count(distinct case when event_type = 'Click' then campaign_id end) as email_clicks,
        count(distinct case when event_type = 'Sent'  then campaign_id end) as emails_received,
        max(case when event_type = 'Open' then event_date end)              as last_email_open_date
    from {{ ref('silver_sf_marketing_cloud') }}
    group by email_address
)

select
    c.customer_id,
    c.crm_contact_id,
    c.full_name,
    c.primary_email,
    c.primary_phone,
    c.email_count,
    c.phone_count,
    c.customer_segment,
    c.membership_type,
    c.membership_status,
    c.donor_tier,
    coalesce(ts.ticket_purchase_count, 0)               as ticket_purchase_count,
    coalesce(ts.total_ticket_spend, 0)                  as total_ticket_spend,
    coalesce(ts.tickets_bought, 0)                      as tickets_bought,
    coalesce(ts.last_ticket_date, '1900-01-01'::date)   as last_ticket_date,
    coalesce(rl.retail_purchase_count, 0)               as retail_purchase_count,
    coalesce(rl.total_retail_spend, 0)                  as total_retail_spend,
    coalesce(rl.retail_items_bought, 0)                 as retail_items_bought,
    coalesce(rl.last_retail_date, '1900-01-01'::date)   as last_retail_date,
    coalesce(da.donation_count, 0)                      as donation_count,
    coalesce(da.total_donations, 0)                     as total_donations,
    coalesce(ts.total_ticket_spend, 0)
        + coalesce(rl.total_retail_spend, 0)            as total_pos_spend,
    coalesce(ts.total_ticket_spend, 0)
        + coalesce(rl.total_retail_spend, 0)
        + coalesce(da.total_donations, 0)               as total_lifetime_value,
    greatest(
        coalesce(ts.last_ticket_date,  '1900-01-01'::date),
        coalesce(rl.last_retail_date,  '1900-01-01'::date),
        coalesce(da.last_donation_date,'1900-01-01'::date)
    )                                                   as last_transaction_date,
    coalesce(ea.email_opens, 0)                         as email_opens,
    coalesce(ea.email_clicks, 0)                        as email_clicks,
    coalesce(ea.emails_received, 0)                     as emails_received,
    ea.last_email_open_date,
    case
        when coalesce(ts.total_ticket_spend,0) + coalesce(rl.total_retail_spend,0)
            + coalesce(da.total_donations,0) >= 1000 then 'High Value'
        when coalesce(ts.total_ticket_spend,0) + coalesce(rl.total_retail_spend,0)
            + coalesce(da.total_donations,0) >= 200  then 'Medium Value'
        when coalesce(ts.total_ticket_spend,0) + coalesce(rl.total_retail_spend,0)
            + coalesce(da.total_donations,0) > 0     then 'Low Value'
        else 'No Spend'
    end                                                 as ltv_tier,
    case
        when ea.email_opens > 5 and ts.last_ticket_date >= dateadd('day', -90, current_date()) then 'Highly Engaged'
        when ea.email_opens > 0 or ts.last_ticket_date >= dateadd('day', -180, current_date()) then 'Engaged'
        else 'Lapsed'
    end                                                 as engagement_segment,
    greatest(
        coalesce(ts.last_ticket_date,  '1900-01-01'::date),
        coalesce(rl.last_retail_date,  '1900-01-01'::date),
        coalesce(ea.last_email_open_date, '1900-01-01'::date)
    )                                                   as last_interaction_date,
    current_timestamp()                                 as _loaded_at
from {{ ref('dim_customer') }} c
left join ticket_agg  ts on c.customer_id = ts.customer_id
left join retail_agg  rl on c.customer_id = rl.customer_id
left join donation_agg da on c.customer_id = da.customer_id
left join email_agg    ea on c.primary_email = ea.email_address
