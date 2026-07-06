/*
  dim_campaign
  Source: fct_campaign_performance (SFMC) + stg_salesforce_nps__campaigns (SF NPS)
  STATUS: Awaiting RAW data.
  Logic migrated from POC.
*/

{{ config(enabled=false,materialized='table') }}

with sfmc_campaigns as (
    select
        campaign_id,
        campaign_name,
        first_send_date,
        last_event_date,
        datediff('day', first_send_date, last_event_date) as campaign_duration_days,
        unique_recipients,
        'Email'                                             as campaign_channel
    from {{ ref('fct_campaign_performance') }}
),

sf_campaigns as (
    select
        campaign_id,
        campaign_name,
        start_date                                          as first_send_date,
        end_date                                            as last_event_date,
        datediff('day', start_date, end_date)               as campaign_duration_days,
        number_of_contacts                                  as unique_recipients,
        campaign_type                                       as campaign_channel
    from {{ ref('stg_salesforce_nps__campaigns') }}
)

select
    campaign_id,
    campaign_name,
    first_send_date,
    last_event_date,
    campaign_duration_days,
    unique_recipients,
    campaign_channel,
    case
        when campaign_name ilike '%member%'     then 'Membership'
        when campaign_name ilike '%donation%'
          or campaign_name ilike '%appeal%'     then 'Fundraising'
        when campaign_name ilike '%newsletter%' then 'Newsletter'
        when campaign_name ilike '%sale%'
          or campaign_name ilike '%shop%'       then 'Retail Promotion'
        when campaign_name ilike '%exhibition%'
          or campaign_name ilike '%promo%'      then 'Exhibition Promotion'
        else 'General'
    end as campaign_type,
    case
        when unique_recipients >= 200 then 'Large'
        when unique_recipients >= 100 then 'Medium'
        else 'Small'
    end as audience_size_tier,
    current_timestamp() as _loaded_at
from sfmc_campaigns
union all
select *, current_timestamp() from sf_campaigns
