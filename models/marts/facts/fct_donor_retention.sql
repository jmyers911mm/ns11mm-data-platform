/*
  fct_donor_retention
  Source: silver_sf_crm + silver_classy + dim_date
  STATUS: Awaiting RAW data. Logic migrated from POC with Classy added.
*/

{{ config(materialized='table') }}

with donors as (
    select
        contact_id,
        email,
        membership_type,
        computed_membership_status,
        donor_tier,
        donation_total_ytd,
        date_trunc('month', created_at)::date               as cohort_month,
        created_at,
        membership_start_date,
        membership_end_date,
        last_donation_date
    from {{ ref('silver_sf_crm') }}
    where donation_total_ytd > 0
),

months as (
    select date_id as month_start
    from {{ ref('dim_date') }}
    where is_first_of_month = true
      and date_id <= current_date()
),

donor_months as (
    select
        d.contact_id,
        d.cohort_month,
        d.membership_type,
        d.donor_tier,
        m.month_start                                       as observation_month,
        datediff('month', d.cohort_month, m.month_start)   as months_since_acquisition,
        d.membership_end_date,
        d.last_donation_date,
        d.donation_total_ytd
    from donors d
    cross join months m
    where m.month_start >= d.cohort_month
)

select
    cohort_month,
    months_since_acquisition,
    observation_month,
    membership_type,
    donor_tier,
    count(distinct contact_id)                              as cohort_size,
    count(distinct case
        when last_donation_date >= observation_month
          or (membership_end_date is null or membership_end_date >= observation_month)
        then contact_id end)                                as retained_donors,
    round(count(distinct case
        when last_donation_date >= observation_month
          or (membership_end_date is null or membership_end_date >= observation_month)
        then contact_id end)::float
        / nullif(count(distinct contact_id), 0) * 100, 2)  as retention_rate_pct,
    current_timestamp()                                     as _loaded_at
from donor_months
group by cohort_month, months_since_acquisition, observation_month, membership_type, donor_tier
