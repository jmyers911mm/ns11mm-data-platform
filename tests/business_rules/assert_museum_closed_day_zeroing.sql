-- Test (business_rule): the legacy museum closed-day zeroing is actually applied
-- Severity: error — t_reporting_mus_attendance forces museum attendance to 0 on a
-- seeded closed day whose scanned passes fall below the seeded threshold. Two
-- failure modes are caught: a flagged day that still prints a non-zero figure,
-- and a day that should have been flagged but was not (rule/seed drift).

with attendance as (
    select
        date_key,
        mus_attendance,
        mus_passes_scanned,
        is_museum_closed_day
    from {{ ref('int_dpr__attendance') }}
),

rules as (
    select rule_type, day_of_week_name, exception_date, min_threshold
    from {{ ref('seed_attendance_zeroing_rule') }}
    where attendance_group = 'museum'
),

expected as (
    select
        a.date_key,
        a.mus_attendance,
        a.mus_passes_scanned,
        a.is_museum_closed_day,
        count(r.min_threshold) > 0 as should_be_zeroed
    from attendance a
    left join rules r
        on (
               (r.rule_type = 'day_of_week'    and dayname(a.date_key) = r.day_of_week_name)
            or (r.rule_type = 'exception_date' and a.date_key          = r.exception_date)
           )
       and coalesce(a.mus_passes_scanned, 0) < r.min_threshold
    group by a.date_key, a.mus_attendance, a.mus_passes_scanned, a.is_museum_closed_day
)

select *
from expected
where is_museum_closed_day <> should_be_zeroed
   or (is_museum_closed_day and coalesce(mus_attendance, -1) <> 0)
