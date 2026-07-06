/*
  rpt_customer_ltv
  Sources: dim_customer, fct_ticket_sales, fct_retail_line_items, fct_fundraising
  STATUS: Awaiting RAW data. Logic migrated from POC with Classy donations added.
*/

{{ config(enabled=false,materialized='table') }}

with ticket_spend as (
    select
        customer_id,
        sum(total_amount)       as total_ticket_spend,
        count(distinct transaction_id) as ticket_visits,
        min(transaction_date)   as first_ticket_date,
        max(transaction_date)   as last_ticket_date,
        avg(total_amount)       as avg_ticket_spend
    from {{ ref('fct_ticket_sales') }}
    where customer_id is not null
    group by customer_id
),

retail_spend as (
    select
        customer_id,
        sum(total_amount)       as total_retail_spend,
        count(distinct transaction_id) as retail_visits,
        min(transaction_date)   as first_retail_date,
        max(transaction_date)   as last_retail_date,
        avg(total_amount)       as avg_retail_spend
    from {{ ref('fct_retail_line_items') }}
    where customer_id is not null
    group by customer_id
),

donation_spend as (
    select
        donor_member_id         as customer_id,
        sum(gross_amount)       as total_donation_spend,
        count(distinct transaction_id) as donation_count,
        max(transaction_date)   as last_donation_date
    from {{ ref('fct_fundraising') }}
    where donor_member_id is not null
    group by donor_member_id
)

select
    c.customer_id,
    c.full_name,
    c.primary_email,
    c.primary_phone,
    c.customer_segment,
    c.membership_type,
    c.membership_status,
    coalesce(ts.total_ticket_spend, 0)              as total_ticket_spend,
    coalesce(rs.total_retail_spend, 0)              as total_retail_spend,
    coalesce(ds.total_donation_spend, 0)            as total_donation_spend,
    coalesce(ts.total_ticket_spend, 0)
        + coalesce(rs.total_retail_spend, 0)
        + coalesce(ds.total_donation_spend, 0)      as total_lifetime_value,
    coalesce(ts.ticket_visits, 0)                   as ticket_visits,
    coalesce(rs.retail_visits, 0)                   as retail_visits,
    coalesce(ds.donation_count, 0)                  as donation_count,
    case
        when coalesce(ts.total_ticket_spend, 0)
           + coalesce(rs.total_retail_spend, 0)
           + coalesce(ds.total_donation_spend, 0) >= 1000 then 'Platinum'
        when coalesce(ts.total_ticket_spend, 0)
           + coalesce(rs.total_retail_spend, 0)
           + coalesce(ds.total_donation_spend, 0) >= 500  then 'Gold'
        when coalesce(ts.total_ticket_spend, 0)
           + coalesce(rs.total_retail_spend, 0)
           + coalesce(ds.total_donation_spend, 0) >= 100  then 'Silver'
        else 'Bronze'
    end                                             as ltv_tier,
    coalesce(ts.first_ticket_date, rs.first_retail_date) as first_transaction_date,
    greatest(
        coalesce(ts.last_ticket_date,  '1900-01-01'),
        coalesce(rs.last_retail_date,  '1900-01-01'),
        coalesce(ds.last_donation_date,'1900-01-01')
    )                                               as last_transaction_date,
    current_timestamp()                             as _loaded_at
from {{ ref('dim_customer') }} c
left join ticket_spend  ts on c.customer_id = ts.customer_id
left join retail_spend  rs on c.customer_id = rs.customer_id
left join donation_spend ds on c.customer_id = ds.customer_id
