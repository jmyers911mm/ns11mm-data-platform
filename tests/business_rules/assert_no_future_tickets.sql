-- Test (business_rule): no future-dated tickets in the pipeline
-- Co-authored with CoCo
-- Severity: error — future dates indicate a source date-mapping defect

select ticket_id, sold_at, ticket_date
from {{ ref('stg_gateway__tickets') }}
where sold_at > dateadd('day', 1, current_timestamp())
   or (ticket_date > dateadd('year', 2, current_date())
       and ticket_date < '2099-01-01')
limit 10
