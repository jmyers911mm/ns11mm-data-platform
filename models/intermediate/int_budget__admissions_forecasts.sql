-- Intermediate: cleanse and type-cast admissions/attendance forecast seed
-- ---------------------------------------------------------------------------
-- Domain: budget
-- Grain:  one row per date_key x key_facility
--
-- Converts key_date (NUMBER 20260101) to DATE, casts mixed TEXT columns to
-- numeric, and coalesces NULLs to zero for additive measures.

{{ config(materialized='view') }}

with source as (
    select * from {{ source('budget_seeds', 'SEED_FORECASTED_VALUE_FOR_DATE') }}
),

cleaned as (
    select
        to_date(key_date::varchar, 'YYYYMMDD')                as date_key,
        key_facility,

        -- Attendance
        coalesce(mem_attendance, 0)                            as mem_attendance,
        coalesce(try_to_number(attend), 0)                    as attend,
        coalesce(new_attendance, 0)                            as mus_attendance,

        -- Admissions
        coalesce(tickets_sold, 0)                              as tickets_sold,
        coalesce(revenue, 0)                                   as ticket_revenue,

        -- Guided tours
        coalesce(guided_tours, 0)                              as mus_guided_tours,
        coalesce(guided_tours_revenue, 0)                      as mus_guided_tour_revenue,

        -- Fees
        coalesce(try_to_number(service_fees, 12, 4), 0)        as service_fees,

        -- CityPASS
        coalesce(citypass_tickets, 0)                          as citypass_tickets,
        coalesce(citypass_revenue, 0)                          as citypass_revenue,

        -- Memorial tours
        coalesce(try_to_number(mem_guided_tours), 0)           as mem_guided_tours,
        coalesce(try_to_number(mem_guided_tours_revenue, 12, 4), 0) as mem_guided_tour_revenue,

        -- Memorial + Museum combo tours
        coalesce(mem_mus_tours, 0)                             as mem_mus_tours,
        coalesce(mem_mus_tour_revenue, 0)                      as mem_mus_tour_revenue

    from source
)

select * from cleaned
