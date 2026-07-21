-- Validates dim_date covers required range (2000-01-01 through 2035-12-31)
-- Co-authored with CoCo
select
    case when min(date_key) > '2000-01-01' then 'FAIL: missing early dates' end as check_start,
    case when max(date_key) < '2035-12-31' then 'FAIL: missing future dates' end as check_end
from {{ ref('dim_date') }}
having min(date_key) > '2000-01-01'
    or max(date_key) < '2035-12-31'
