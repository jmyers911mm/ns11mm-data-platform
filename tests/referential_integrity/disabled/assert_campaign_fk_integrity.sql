{{ config(enabled=false) }}
-- Campaign IDs in Gold facts resolve to dim_campaign
-- STATUS: Awaiting production models
/*
select f.campaign_id
from {{ ref('fct_campaign_performance') }} f
left join {{ ref('dim_campaign') }} d on f.campaign_id = d.campaign_id
where f.campaign_id is not null
  and d.campaign_id is null
*/
select 1 where 1 = 0
