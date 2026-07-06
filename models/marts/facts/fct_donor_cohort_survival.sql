/*
  fct_donor_cohort_survival
  Source: fct_donor_retention
  STATUS: Awaiting RAW data. Logic migrated from POC.
*/

{{ config(enabled=false,materialized='table', cluster_by=['months_since_acquisition']) }}

with retention as (
    select * from {{ ref('fct_donor_retention') }}
),
survival_by_cohort as (
    select
        cohort_month, membership_type, donor_tier,
        months_since_acquisition,
        coalesce(max(case when months_since_acquisition = 0 then cohort_size end)
            over (partition by cohort_month, membership_type, donor_tier), cohort_size) as original_cohort_size,
        retained_donors,
        retention_rate_pct,
        lag(retention_rate_pct) over (
            partition by cohort_month, membership_type, donor_tier
            order by months_since_acquisition
        ) as prev_month_retention_pct,
        retention_rate_pct - coalesce(lag(retention_rate_pct) over (
            partition by cohort_month, membership_type, donor_tier
            order by months_since_acquisition
        ), 100) as monthly_retention_change_pct
    from retention
)

select
    cohort_month, membership_type, donor_tier, months_since_acquisition,
    original_cohort_size, retained_donors,
    retention_rate_pct                                      as survival_rate_pct,
    monthly_retention_change_pct                            as monthly_dropoff_pct,
    case
        when months_since_acquisition = 0 then null
        when retention_rate_pct <= 50 and coalesce(prev_month_retention_pct, 100) > 50 then true
        else false
    end                                                     as is_half_life_month,
    case
        when retention_rate_pct > 80 then 'Healthy'
        when retention_rate_pct > 50 then 'At Risk'
        when retention_rate_pct > 25 then 'Declining'
        else 'Critical'
    end                                                     as cohort_health,
    current_timestamp()                                     as _loaded_at
from survival_by_cohort
