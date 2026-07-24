/*
  dim_date — Date dimension spanning 2000-01-01 to 2035-12-31.
  Fully self-contained; no upstream source dependency.
  Includes NS11MM-specific flags: is_commemoration_day (September 11 anniversary).
*/
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
)
select * from final