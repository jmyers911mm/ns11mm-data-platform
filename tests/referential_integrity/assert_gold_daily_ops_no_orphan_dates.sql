-- Validates all dates in fct_daily_operations exist in dim_date
-- Co-authored with CoCo

select f.visit_date
from {{ ref('fct_daily_operations') }} f
left join {{ ref('dim_date') }} d on f.visit_date = d.date_id
where d.date_id is null
