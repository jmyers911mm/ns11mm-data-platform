{{ config(enabled=false) }}
-- Validates ticket types in facts exist in ref_ticket_types seed
-- STATUS: Awaiting production models
/*
select f.ticket_type_id
from {{ ref('fct_ticket_sales') }} f
left join {{ ref('ref_ticket_types') }} s on f.ticket_type_id = s.ticket_type_id
where f.ticket_type_id is not null
  and s.ticket_type_id is null
group by 1
*/
select 1 where 1 = 0
