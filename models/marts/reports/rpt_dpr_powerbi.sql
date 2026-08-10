-- Marts report: thin SEMANTIC_VIEW() projection of the DPR semantic view for Power BI
-- ---------------------------------------------------------------------------
-- Domain: DPR
-- Grain:  one row per report_date
--
-- Thin day-grain wrapper over the MARTS.DPR semantic view: Power BI's native
-- Snowflake connector cannot browse a SEMANTIC VIEW object, so this wraps the
-- SEMANTIC_VIEW() query in a normal view Power BI can import. Every metric
-- DEFINITION stays in the semantic view. Feeds the Power BI Daily Performance
-- Report dataset, rpt_dpr_report_long, and rpt_dpr_narrative_brief.
-- NOTE: non-additive ratios (avg ticket price, per-cap) are intentionally NOT
-- selected; DAX recomputes them from the summed components included here.
--
-- ADR-004: all business logic in dbt / the semantic view, never Power BI.

{{ config(materialized='view', grants={'select': ['POWERBI_ROLE']}) }}

select * from semantic_view(
    {{ source('dpr_semantic', 'DPR') }}

    dimensions
        dt.report_date          as report_date,
        dt.calendar_year        as calendar_year,
        dt.calendar_quarter     as calendar_quarter,
        dt.calendar_month       as calendar_month,
        dt.month_name           as month_name,
        dt.day_of_month         as day_of_month,
        dt.day_name             as day_name,
        dt.is_weekend           as is_weekend,
        dp.is_commemoration_day as is_commemoration_day

    metrics
        dp.total_memorial_attendance         as memorial_attendance,
        dp.total_museum_attendance           as museum_attendance,
        dp.total_tickets_sold                as tickets_sold,
        dp.total_ticket_revenue              as ticket_revenue,
        dp.total_pass_revenue                as pass_revenue,
        dp.total_admission_revenue           as admission_revenue,
        dp.total_mem_mus_tours               as mem_mus_tours,
        dp.total_mem_mus_tour_revenue        as mem_mus_tour_revenue,
        dp.total_museum_guided_tours         as museum_guided_tours,
        dp.total_mus_guided_tour_revenue     as mus_guided_tour_revenue,
        dp.total_memorial_guided_tours       as memorial_guided_tours,
        dp.total_mem_guided_tour_revenue     as mem_guided_tour_revenue,
        dp.total_revealed_tour_revenue       as revealed_tour_revenue,
        dp.total_virtual_tour_revenue        as virtual_tour_revenue,
        dp.total_virtual_yf_mem_tour_revenue as virtual_yf_tour_revenue,
        dp.total_mus_store_gross_profit      as mus_store_gross_profit,
        dp.total_retail_carts_gross_profit   as retail_carts_gross_profit,
        dp.total_cafe_profit                 as cafe_profit,
        dp.total_audio_tour_headset          as audio_tour_headset,
        dp.total_cart_donation_ask           as cart_donation_ask,
        dp.total_box_office_mem_donations    as box_office_mem_don,
        dp.total_donation_box                as donation_box,
        dp.total_ecom_donation_ask           as ecom_donation_ask,
        dp.total_ticketing_donations         as ticketing_donations,
        dp.total_box_office_mus_exit_donations as box_office_mus_exit_don,
        dp.total_coatcheck_donations         as coatcheck_don,
        dp.total_mus_store_donations         as mus_store_don,
        dp.total_mus_exit_donations          as mus_exit_don,
        dp.total_cafe_donations              as cafe_don,

        -- 7.12.5: metrics the MTD/YTD workbooks print that were already
        -- authored in the DPR semantic view but not projected here.
        dp.total_service_fees                as service_fees,
        dp.total_mask_donations              as mask_donations,
        dp.total_mem_audio_guide_revenue     as mem_audio_guide_revenue,
        dp.total_ask_educator_revenue        as ask_educator_revenue,
        dp.total_retail_gross_profit         as total_retail_gross_profit,
        dp.total_donations                   as total_donations,
        dp.total_audio_tour_headset_units    as audio_tour_headset_units,
        dp.total_memorial_field_trips        as memorial_field_trips,
        dp.total_mem_field_trip_revenue      as mem_field_trip_revenue,
        dp.total_museum_field_trips          as museum_field_trips,
        dp.total_mus_field_trip_revenue      as mus_field_trip_revenue,
        dp.total_field_trip_revenue          as field_trip_revenue,
        dp.total_virtual_mem_tours           as virtual_mem_tours,
        dp.total_virtual_mem_tour_revenue    as virtual_mem_tour_revenue,
        dp.total_virtual_mus_tours           as virtual_mus_tours,
        dp.total_virtual_mus_tour_revenue    as virtual_mus_tour_revenue,
        dp.total_virtual_yf_mem_tours        as virtual_yf_mem_tours
)