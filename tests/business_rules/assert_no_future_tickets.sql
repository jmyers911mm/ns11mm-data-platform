-- Asserts no future-dated tickets in the pipeline (data quality check)
-- Co-authored with CoCo

select ticket_id, sold_at, ticket_date
from {{ ref('stg_gateway__tickets') }}
where sold_at > dateadd('day', 1, current_timestamp())
   or (ticket_date > dateadd('year', 2, current_date()) and ticket_date < '3000-01-01')
limit 10
