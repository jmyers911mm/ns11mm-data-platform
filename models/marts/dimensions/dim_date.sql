-- Marts dimension: dim_date — conformed date spine, 2000-01-01 to 2035-12-31
-- Co-authored with CoCo
-- ---------------------------------------------------------------------------
-- Domain: shared (date spine)
-- Grain: one row per calendar date
--
-- Fully self-contained; no upstream source dependency. Includes NS11MM-specific
-- flags: is_commemoration_day (September 11 anniversary).

{{ config(materialized='table', tags=['daily', 'critical']) }}
with date_spine as (
    select dateadd(day, seq4(), '2000-01-01'::date) as date_day
    from table(generator(rowcount => 13149))
),
holiday_flags as (
    select
        date_day,
        case
            when month(date_day) = 1  and day(date_day) = 1  then 'New Year''s Day'
            when month(date_day) = 6  and day(date_day) = 19 and year(date_day) >= 2021 then 'Juneteenth'
            when month(date_day) = 7  and day(date_day) = 4  then 'Independence Day'
            when month(date_day) = 11 and day(date_day) = 11 then 'Veterans Day'
            when month(date_day) = 12 and day(date_day) = 25 then 'Christmas Day'
            when month(date_day) = 1  and dayofweek(date_day) = 1 and ceil(day(date_day) / 7.0) = 3 then 'Martin Luther King Jr. Day'
            when month(date_day) = 2  and dayofweek(date_day) = 1 and ceil(day(date_day) / 7.0) = 3 then 'Washington''s Birthday'
            when month(date_day) = 5  and dayofweek(date_day) = 1 and month(dateadd(day, 7, date_day)) <> 5 then 'Memorial Day'
            when month(date_day) = 9  and dayofweek(date_day) = 1 and ceil(day(date_day) / 7.0) = 1 then 'Labor Day'
            when month(date_day) = 10 and dayofweek(date_day) = 1 and ceil(day(date_day) / 7.0) = 2 then 'Columbus Day'
            when month(date_day) = 11 and dayofweek(date_day) = 4 and ceil(day(date_day) / 7.0) = 4 then 'Thanksgiving Day'
            else null
        end as holiday_name
    from date_spine
),
final as (
    select
        date_day                                                         as date_key,
        date_day,
        dateadd(day, -1 * dayofweek(date_day), date_day)                 as first_day_of_week,
        dateadd(day, 6 - dayofweek(date_day), date_day)                  as last_day_of_week,
        date_trunc('month', date_day)::date                              as first_day_of_month,
        last_day(date_day, 'month')                                      as last_day_of_month,
        date_trunc('quarter', date_day)::date                            as first_day_of_quarter,
        last_day(date_day, 'quarter')                                    as last_day_of_quarter,
        date_trunc('year', date_day)::date                               as first_day_of_year,
        last_day(date_day, 'year')                                       as last_day_of_year,
        dayofweek(date_day)                                              as day_of_week,
        dayname(date_day)                                                as day_of_week_name,
        day(date_day)                                                    as day_of_month,
        dayofyear(date_day)                                              as day_of_year,
        weekofyear(date_day)                                             as week_of_year,
        month(date_day)                                                  as month_of_year,
        monthname(date_day)                                              as month_name,
        quarter(date_day)                                                as quarter_of_year,
        year(date_day)                                                   as year_number,
        case when dayofweek(date_day) in (0, 6) then true else false end as is_weekend,
        case when dayofweek(date_day) in (0, 6) then false else true end as is_weekday,
        case
            when month(date_day) = 9 and day(date_day) = 11 then true
            when month(date_day) = 2 and day(date_day) = 26 then true
            else false
        end                                                              as is_commemoration_day,
        case when day(date_day) = 1 then true else false end             as is_first_of_month,
        case
            when date_day = last_day(date_day) then true
            else false
        end                                                              as is_last_of_month,
        holiday_name,
        case when holiday_name is not null then true else false end      as is_holiday
    from holiday_flags
),

-- =====================================================================
-- Period-to-date (WTD/MTD/QTD/YTD) flags with same-day-last-year (SDLY)
-- counterparts for the current year + prior 5 years.
-- =====================================================================

-- One row per comparison year. anchor_date is shifted -364 days per year
-- (52 whole weeks) so it always lands on the same weekday as today.
anchors as (
    select
        n                                          as years_ago,
        dateadd(day, -364 * n, current_date())     as anchor_date
    from ( values (0), (1), (2), (3), (4), (5) ) as v(n)
),

-- The four period-to-date windows [start .. anchor] for each comparison year.
-- wtd_start mirrors this model's own first_day_of_week (Sunday start, dayofweek 0=Sun).
windows as (
    select
        years_ago,
        anchor_date,
        dateadd(day, -1 * dayofweek(anchor_date), anchor_date) as wtd_start,
        date_trunc('month',   anchor_date)::date              as mtd_start,
        date_trunc('quarter', anchor_date)::date              as qtd_start,   -- calendar quarter
        date_trunc('year',    anchor_date)::date              as ytd_start    -- calendar year (Jan 1)
    from anchors
),

-- For each calendar day, which comparison year (if any) it falls into, per period.
-- Windows never overlap across years, so max() extracts the single matching years_ago.
ptd as (
    select
        f.date_key,
        max(case when f.date_key = w.anchor_date then w.years_ago end) as today_years_ago,
        max(case when f.date_key = dateadd(day, -1, w.anchor_date) then w.years_ago end) as yesterday_years_ago,
        max(case when f.date_key between w.wtd_start and w.anchor_date then w.years_ago end) as wtd_years_ago,
        max(case when f.date_key between w.mtd_start and w.anchor_date then w.years_ago end) as mtd_years_ago,
        max(case when f.date_key between w.qtd_start and w.anchor_date then w.years_ago end) as qtd_years_ago,
        max(case when f.date_key between w.ytd_start and w.anchor_date then w.years_ago end) as ytd_years_ago
    from final f
    cross join windows w
    group by f.date_key
)

select
    f.*,
    iff(p.today_years_ago is not null, 'YES', 'NO')  as today_flag,
    iff(p.yesterday_years_ago is not null, 'YES', 'NO')  as yesterday_flag,
    iff(p.wtd_years_ago is not null, 'YES', 'NO')  as wtd_flag,
    iff(p.mtd_years_ago is not null, 'YES', 'NO')  as mtd_flag,
    iff(p.qtd_years_ago is not null, 'YES', 'NO')  as qtd_flag,
    iff(p.ytd_years_ago is not null, 'YES', 'NO')  as ytd_flag,
    -- COALESCE (not OR) so comparison year 0 is preserved; widest window first.
    coalesce(p.ytd_years_ago, p.qtd_years_ago, p.mtd_years_ago, p.wtd_years_ago)
                                                   as comparison_years_ago
from final f
left join ptd p on f.date_key = p.date_key