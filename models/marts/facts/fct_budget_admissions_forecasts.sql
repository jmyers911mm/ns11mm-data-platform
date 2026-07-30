-- Marts fact: admissions/attendance budget by facility (one row per day x facility)
-- ---------------------------------------------------------------------------
-- Domain: budget
-- Grain: one row per date_key x key_facility
--
-- Budget/forecast counterpart to admissions actuals. Attendance, tickets,
-- tours, CityPASS by facility per day. Joined to dim_date for the conformed
-- date key.

{{ config(
    materialized='table',
    cluster_by=['date_key']
) }}

with budget as (
    select * from {{ ref('int_budget__admissions_forecasts') }}
),

final as (
    select
        dd.date_key,
        b.date_key                  as date_value,
        b.key_facility,

        -- Attendance
        b.mem_attendance,
        b.attend,
        b.mus_attendance,

        -- Admissions
        b.tickets_sold,
        b.ticket_revenue,

        -- Tours
        b.mus_guided_tours,
        b.mus_guided_tour_revenue,
        b.mem_guided_tours,
        b.mem_guided_tour_revenue,
        b.mem_mus_tours,
        b.mem_mus_tour_revenue,

        -- Fees
        b.service_fees,

        -- CityPASS
        b.citypass_tickets,
        b.citypass_revenue

    from budget b
    inner join {{ ref('dim_date') }} dd
        on b.date_key = dd.date_key
)

select * from final
