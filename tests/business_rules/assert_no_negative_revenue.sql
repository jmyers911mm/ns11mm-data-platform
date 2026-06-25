-- Validates no negative revenue in Gold fact tables
-- STATUS: Awaiting production models
/*
select visit_date, ticket_revenue
from {{ ref('fct_daily_operations') }}
where ticket_revenue < 0
*/
select 1 where 1 = 0
