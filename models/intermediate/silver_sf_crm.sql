/*
  silver_sf_crm
  Source: stg_salesforce_nps__contacts + stg_salesforce_nps__opportunities
  Grain: one row per contact
  Enriches contacts with membership and donation data from Opportunities.
*/

{{
    config(
        enabled=false,
        materialized='incremental',
        unique_key='contact_id',
        incremental_strategy='merge',
        on_schema_change='append_new_columns',
        cluster_by=['computed_membership_status', 'membership_type'],
        tags=['daily', 'critical']
    )
}}

with contacts as (
    select * from {{ ref('stg_salesforce_nps__contacts') }}
    {% if is_incremental() %}
    where _extracted_at > (select max(_extracted_at) from {{ this }})
    {% endif %}
),

opportunities as (
    select * from {{ ref('stg_salesforce_nps__opportunities') }}
),

membership_opps as (
    select
        o.account_id,
        o.opportunity_type                                       as membership_type,
        o.stage_name                                             as membership_status,
        min(o.close_date)                                        as membership_start_date,
        max(o.close_date)                                        as membership_end_date
    from opportunities o
    where o.opportunity_type ilike '%member%'
      and o.stage_name in ('Closed Won', 'Active', 'Renewed')
    group by o.account_id, o.opportunity_type, o.stage_name
),

donation_opps as (
    select
        o.account_id,
        sum(case
            when o.close_date >= date_trunc('year', current_date())
            then o.amount else 0
        end)                                                     as donation_total_ytd,
        max(o.close_date)                                        as last_donation_date
    from opportunities o
    where o.stage_name = 'Closed Won'
      and (o.opportunity_type ilike '%donat%' or o.opportunity_type ilike '%gift%')
    group by o.account_id
)

select
    c.contact_id,
    c.first_name,
    c.last_name,
    c.first_name || ' ' || c.last_name                     as full_name,
    c.email,
    c.phone,
    m.membership_type,
    m.membership_status,
    case
        when m.membership_status in ('Active', 'Renewed') then 'Active'
        when m.membership_status is not null then 'Inactive'
        else 'Unknown'
    end                                                     as computed_membership_status,
    m.membership_start_date,
    m.membership_end_date,
    coalesce(d.donation_total_ytd, 0)                       as donation_total_ytd,
    case
        when coalesce(d.donation_total_ytd, 0) >= 5000 then 'Major Donor'
        when coalesce(d.donation_total_ytd, 0) >= 1000 then 'Mid-Level Donor'
        when coalesce(d.donation_total_ytd, 0) >= 100  then 'Donor'
        when coalesce(d.donation_total_ytd, 0) > 0     then 'Small Donor'
        else 'Non-Donor'
    end                                                     as donor_tier,
    d.last_donation_date,
    null::date                                              as last_visit_date,
    c.created_at,
    c.last_modified_at,
    c.hashdiff,
    c._extracted_at
from contacts c
left join {{ ref('stg_salesforce_nps__accounts') }} a
    on c.account_id = a.account_id
left join membership_opps m
    on c.account_id = m.account_id
left join donation_opps d
    on c.account_id = d.account_id
