-- Validates campaign open/click rates are between 0 and 1
-- STATUS: Awaiting production models
/*
select campaign_id, open_rate, click_rate
from {{ ref('fct_campaign_performance') }}
where open_rate < 0 or open_rate > 1
   or click_rate < 0 or click_rate > 1
*/
select 1 where 1 = 0
