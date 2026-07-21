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

final as (
    select
        date_day                                                         as date_key,
        date_day,
        dayofweek(date_day)                                              as day_of_week,
        dayname(date_day)                                                as day_of_week_name,
        day(date_day)                                                    as day_of_month,
        dayofyear(date_day)                                              as day_of_year,
        weekofyear(date_day)                                             as week_of_year,
        month(date_day)                                                  as month_of_year,
        monthname(date_day)                                              as month_name,
        quarter(date_day)                                                as quarter_of_year,
        year(date_day)                                                   as year_number,
        case
            when month(date_day) >= 10 then year(date_day) + 1
            else year(date_day)
        end                                                              as fiscal_year,
        case
            when month(date_day) >= 10 then month(date_day) - 9
            else month(date_day) + 3
        end                                                              as fiscal_month,
        case when dayofweek(date_day) in (0, 6) then true else false end as is_weekend,
        case when dayofweek(date_day) in (0, 6) then false else true end as is_weekday,
        case
            when month(date_day) = 9 and day(date_day) = 11 then true
            else false
        end                                                              as is_commemoration_day,
        case when day(date_day) = 1 then true else false end             as is_first_of_month,
        case
            when date_day = last_day(date_day) then true
            else false
        end                                                              as is_last_of_month
    from date_spine
)

select * from final