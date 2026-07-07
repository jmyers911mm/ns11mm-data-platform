{{ config(enabled=false) }}
-- Validates customer segment values in dim_customer match ref_customer_segments seed
-- STATUS: Awaiting production models
/*
select d.segment
from {{ ref('dim_customer') }} d
left join {{ ref('ref_customer_segments') }} s on d.segment = s.segment_name
where d.segment is not null
  and s.segment_name is null
group by 1
*/
select 1 where 1 = 0
