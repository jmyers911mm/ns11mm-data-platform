-- Validates no negative revenue in fct_daily_operations
-- Co-authored with CoCo

select visit_date, ticket_revenue
from {{ ref('fct_daily_operations') }}
where ticket_revenue < 0
