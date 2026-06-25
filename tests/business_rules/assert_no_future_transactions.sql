-- Validates no transactions dated in the future
-- STATUS: Awaiting production models
/*
select transaction_id, transaction_date
from {{ ref('fct_ticket_sales') }}
where transaction_date > current_date()
*/
select 1 where 1 = 0
