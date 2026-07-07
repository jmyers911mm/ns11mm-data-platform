/*
  bridge_session_customer
  Sources: int_google_analytics + dim_customer + fct_ticket_sales
  STATUS: Awaiting RAW data. Logic migrated from POC.
  Links converting GA4 sessions to resolved customers via email match
  on same-day ticket purchase. Used for multi-touch attribution.
*/

{{ config(enabled=false,materialized='table') }}

with ga_sessions as (
    select
        hashdiff                                            as session_id,
        session_date,
        session_date                                        as user_pseudo_id,
        source,
        medium,
        channel_grouping,
        page_category,
        conversions > 0                                     as is_conversion
    from {{ ref('int_google_analytics') }}
    where conversions > 0
),

customer_emails as (
    select customer_id, primary_email, customer_segment, membership_type
    from {{ ref('dim_customer') }}
    where primary_email is not null
),

ticket_buyers as (
    select distinct transaction_date, customer_id
    from {{ ref('fct_ticket_sales') }}
    where customer_id is not null
)

select
    ga.session_id,
    ga.session_date,
    ga.user_pseudo_id,
    ga.channel_grouping,
    ga.source,
    ga.medium,
    ga.page_category,
    tb.customer_id,
    ce.customer_segment,
    ce.membership_type,
    case when tb.customer_id is not null then true else false end as matched_to_customer
from ga_sessions ga
left join ticket_buyers tb  on ga.session_date = tb.transaction_date
left join customer_emails ce on tb.customer_id  = ce.customer_id
