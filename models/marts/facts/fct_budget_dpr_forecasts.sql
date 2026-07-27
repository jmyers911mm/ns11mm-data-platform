-- Mart fact: DPR budget/forecast (one row per day)
-- ---------------------------------------------------------------------------
-- Domain: budget
-- Grain:  one row per date_key
--
-- Budget/forecast counterpart to fct_daily_performance. All additive DPR
-- budget lines — tickets, revenue, audio, donations, ecommerce, cafe, tours.
-- Joined to dim_date for the conformed date key.

{{ config(
    materialized='table',
    cluster_by=['date_key']
) }}

with budget as (
    select * from {{ ref('int_budget__dpr_forecasts') }}
),

final as (
    select
        dd.date_key,
        b.date_key                  as date_value,

        -- Admissions
        b.tickets_sold,
        b.ticket_revenue,
        b.pass_revenue,
        b.ticket_revenue
          + b.pass_revenue          as total_admission_revenue,
        b.service_fees,
        b.donations_ticketing,

        -- Audio
        b.audio_guide_rentals,
        b.audio_guide_capture_rate,
        b.headphone_rentals,
        b.headphone_capture_rate,
        b.audio_guide_revenue,
        b.headphone_revenue,
        b.audio_tour_headsets,
        b.audio_tour_headsets_units_sold,

        -- Memorial audio
        b.mem_audio_guide_rentals,
        b.mem_audio_guide_revenue,
        b.mem_audio_guide_headset,

        -- Donations
        b.coatcheck_donations,
        b.museum_exit_donations,

        -- Ecommerce
        b.ecom_orders,
        b.profit_from_ecom,
        b.total_sales_ecom,
        b.avg_sale_ecom,

        -- Cafe
        b.cafe_transactions,
        b.cafe_donations,
        b.licensing_fees,
        b.cafe_revenue,

        -- Tours
        b.early_access_tours,
        b.early_access_tour_rev,
        b.youth_fam_tours,
        b.youth_fam_tour_rev

    from budget b
    inner join {{ ref('dim_date') }} dd
        on b.date_key = dd.date_key
)

select * from final
