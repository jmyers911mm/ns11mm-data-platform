-- Test (business_rule): no negative attendance counts in DPR fact
-- Severity: error — negative attendance indicates upstream scan aggregation defect

select date_key, mem_attendance, mus_attendance
from {{ ref('fct_daily_performance') }}
where mem_attendance < 0
   or mus_attendance < 0
