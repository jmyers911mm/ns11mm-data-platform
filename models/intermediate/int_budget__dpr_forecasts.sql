-- Intermediate: cleanse and type-cast DPR budget/forecast seed
-- ---------------------------------------------------------------------------
-- Domain: budget
-- Grain:  one row per date_key
--
-- Converts key_date (NUMBER 20260101) to DATE, casts mixed TEXT columns to
-- numeric, and coalesces NULLs to zero for additive measures.

{{ config(materialized='view') }}

with source as (
    select * from {{ source('budget_seeds', 'SEED_DPR_FORECASTS') }}
),

cleaned as (
    select
        to_date(key_date::varchar, 'YYYYMMDD')             as date_key,

        -- Admissions
        coalesce(tickets_sold_for_date, 0)                 as tickets_sold,
        coalesce(ticket_revenue, 0)                        as ticket_revenue,
        coalesce(pass_revenue, 0)                          as pass_revenue,
        coalesce(try_to_number(service_fees, 12, 4), 0)    as service_fees,
        coalesce(donations_ticketing, 0)                   as donations_ticketing,

        -- Audio
        coalesce(try_to_number(audio_guide_rentals), 0)    as audio_guide_rentals,
        try_to_double(audio_guide_capture_rate)            as audio_guide_capture_rate,
        coalesce(try_to_number(headphone_rental), 0)       as headphone_rentals,
        try_to_double(headphone_capture_rate)              as headphone_capture_rate,
        coalesce(try_to_number(audio_guide_revenue, 12, 4), 0) as audio_guide_revenue,
        coalesce(try_to_number(headphone_revenue, 12, 4), 0)   as headphone_revenue,
        coalesce(audio_tour_headsets, 0)                   as audio_tour_headsets,
        coalesce(audio_tour_headsets_units_sold, 0)        as audio_tour_headsets_units_sold,

        -- Donations
        coalesce(coatcheck_donations, 0)                   as coatcheck_donations,
        coalesce(museum_exit_donations, 0)                 as museum_exit_donations,

        -- Ecommerce
        coalesce(ecom_orders, 0)                           as ecom_orders,
        coalesce(profit_from_ecom, 0)                      as profit_from_ecom,
        coalesce(total_sales_ecom, 0)                      as total_sales_ecom,
        coalesce(avg_sale_ecom, 0)                         as avg_sale_ecom,

        -- Cafe
        coalesce(try_to_number(cafe_transactions), 0)      as cafe_transactions,
        coalesce(try_to_number(cafe_donations, 12, 4), 0)  as cafe_donations,
        coalesce(try_to_number(licensing_fees, 12, 4), 0)  as licensing_fees,
        coalesce(cafe_revenue, 0)                          as cafe_revenue,

        -- Tours
        coalesce(early_access_tours, 0)                    as early_access_tours,
        coalesce(early_access_tour_rev, 0)                 as early_access_tour_rev,
        coalesce(try_to_number(youth_fam_tours), 0)        as youth_fam_tours,
        coalesce(try_to_number(youth_fam_tour_rev, 12, 4), 0) as youth_fam_tour_rev,

        -- Memorial audio
        coalesce(try_to_number(mem_audio_guide_rentals), 0)      as mem_audio_guide_rentals,
        coalesce(try_to_number(mem_audio_guide_revenue, 12, 4), 0) as mem_audio_guide_revenue,
        coalesce(try_to_number(mem_audio_guide_headset, 12, 4), 0) as mem_audio_guide_headset

    from source
)

select * from cleaned
