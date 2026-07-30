-- Test (business_rule): no negative ticket_revenue in fct_daily_operations
-- Severity: error — negative revenue indicates a sign / aggregation defect

select visit_date, ticket_revenue
from {{ ref('fct_daily_operations') }}
where ticket_revenue < 0
