/*
  dim_customer
  Source: int_sf_crm + int_pos_tickets + int_pos_retail
  STATUS: Awaiting RAW data.
  Logic migrated from POC dim_customer.sql with production refs.
  Identity resolution: shared email OR phone merges records into one customer_id.
*/

{{ config(enabled=false,materialized='table', cluster_by=['customer_id']) }}

with tickets as (
    select lower(trim(customer_email)) as identifier_value, 'EMAIL' as identifier_type, 'GATEWAY' as source_system, transaction_id as source_id
    from {{ ref('int_pos_tickets') }} where customer_email is not null
    union all
    select trim(customer_phone), 'PHONE', 'GATEWAY', transaction_id
    from {{ ref('int_pos_tickets') }} where customer_phone is not null
),

retail as (
    select lower(trim(customer_email)), 'EMAIL', 'COUNTERPOINT', transaction_id
    from {{ ref('int_pos_retail') }} where customer_email is not null
    union all
    select trim(customer_phone), 'PHONE', 'COUNTERPOINT', transaction_id
    from {{ ref('int_pos_retail') }} where customer_phone is not null
),

crm as (
    select lower(trim(email)), 'EMAIL', 'SALESFORCE_NPS', contact_id
    from {{ ref('int_sf_crm') }} where email is not null
    union all
    select trim(phone), 'PHONE', 'SALESFORCE_NPS', contact_id
    from {{ ref('int_sf_crm') }} where phone is not null
),

all_identifiers as (
    select * from tickets
    union all select * from retail
    union all select * from crm
),

email_phone_pairs as (
    select distinct e.identifier_value as email, p.identifier_value as phone
    from all_identifiers e
    inner join all_identifiers p
        on e.source_system = p.source_system and e.source_id = p.source_id
    where e.identifier_type = 'EMAIL' and p.identifier_type = 'PHONE'
),

customer_clusters as (
    select
        email, phone,
        min(email) over (partition by phone) as cluster_email_by_phone,
        min(phone) over (partition by email) as cluster_phone_by_email
    from email_phone_pairs
),

resolved as (
    select
        coalesce(email, cluster_email_by_phone) as resolved_email,
        coalesce(phone, cluster_phone_by_email) as resolved_phone,
        md5(coalesce(
            min(email) over (partition by coalesce(phone, cluster_phone_by_email)),
            email, phone
        )) as customer_id
    from customer_clusters
),

customer_keys as (
    select distinct customer_id, resolved_email as email, resolved_phone as phone
    from resolved
    union
    select distinct
        md5(identifier_value) as customer_id,
        case when identifier_type = 'EMAIL' then identifier_value end as email,
        case when identifier_type = 'PHONE' then identifier_value end as phone
    from all_identifiers
    where identifier_value not in (
        select email from email_phone_pairs union all select phone from email_phone_pairs
    )
),

grouped as (
    select
        customer_id,
        array_agg(distinct email) within group (order by email) as emails,
        array_agg(distinct phone) within group (order by phone) as phones,
        min(email) as primary_email,
        min(phone) as primary_phone,
        count(distinct email) as email_count,
        count(distinct phone) as phone_count
    from customer_keys
    where email is not null or phone is not null
    group by customer_id
),

crm_match as (
    select g.customer_id, c.contact_id as crm_contact_id,
           c.first_name, c.last_name,
           c.first_name || ' ' || c.last_name as full_name,
           c.computed_membership_status as membership_status,
           c.membership_type, c.donor_tier, c.donation_total_ytd
    from grouped g
    left join {{ ref('int_sf_crm') }} c on g.primary_email = c.email
)

select
    g.customer_id,
    m.crm_contact_id,
    m.full_name,
    m.first_name,
    m.last_name,
    g.primary_email,
    g.primary_phone,
    g.email_count,
    g.phone_count,
    g.emails,
    g.phones,
    m.membership_type,
    m.membership_status,
    m.donor_tier,
    m.donation_total_ytd,
    case
        when m.crm_contact_id is not null and m.membership_status = 'Active' then 'Known Member'
        when m.crm_contact_id is not null then 'Identified Visitor'
        else 'Anonymous'
    end as customer_segment,
    current_timestamp() as _loaded_at
from grouped g
left join crm_match m on g.customer_id = m.customer_id
