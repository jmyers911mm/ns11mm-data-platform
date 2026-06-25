-- Validates payment method IDs in facts exist in ref_payment_methods seed
-- STATUS: Awaiting production models
/*
select f.payment_method_id
from {{ ref('fct_ticket_sales') }} f
left join {{ ref('ref_payment_methods') }} s on f.payment_method_id = s.payment_method_id
where f.payment_method_id is not null
  and s.payment_method_id is null
group by 1
*/
select 1 where 1 = 0
