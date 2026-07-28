-- Test (referential_integrity): every fct_daily_operations visit_date exists in dim_date
-- Co-authored with CoCo
-- Severity: error — orphan dates break date-dimension joins in reporting

select f.visit_date
from {{ ref('fct_daily_operations') }} f
left join {{ ref('dim_date') }} d on f.visit_date = d.date_key
where d.date_key is null
