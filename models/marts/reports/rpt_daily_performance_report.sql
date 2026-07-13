-- Marts report: Daily Performance Report (Power BI consumption layer)
-- Co-authored with CoCo
-- ---------------------------------------------------------------------------
-- Domain: DPR
-- Grain:  one row per date_value
--
-- Presentation model the DPR reads. Provides TODAY, month-to-date and
-- year-to-date roll-ups of the additive measures from fct_daily_performance,
-- plus the NON-ADDITIVE ratios (avg ticket price, per-capita profit)
-- computed at this grain rather than re-aggregated (additive/non-additive
-- ADR: ratios must be recomputed from summed numerator/denominator).
--
-- MTD/YTD use window sums partitioned by period so Power BI does zero
-- aggregation (ADR-004). Variance vs. budget is intentionally omitted until
-- the budget sources (AdmissionDailies / RetailDailies spreadsheets ->
-- fact_dpr_forecasts / fact_retail_forecasts) are staged; those columns are
-- gated on the ADR-005 workshop and the Raiser's Edge / budget scope
-- decision.

{{ config(materialized='table') }}

with fct as (
    select
        f.*,
        dd.year_number   as calendar_year,
        dd.month_of_year as calendar_month
    from {{ ref('fct_daily_performance') }} f
    inner join {{ ref('dim_date') }} dd
        on f.date_id = dd.date_id
),

with_periods as (
    select
        *,

        -- MTD sums (additive measures only)
        sum(ticket_revenue) over (
            partition by calendar_year, calendar_month order by date_value
        )                                                                  as ticket_revenue_mtd,
        sum(total_admission_revenue) over (
            partition by calendar_year, calendar_month order by date_value
        )                                                                  as total_admission_revenue_mtd,
        sum(tickets_sold) over (
            partition by calendar_year, calendar_month order by date_value
        )                                                                  as tickets_sold_mtd,
        sum(mus_store_gross_profit) over (
            partition by calendar_year, calendar_month order by date_value
        )                                                                  as mus_store_gross_profit_mtd,
        sum(mus_attendance) over (
            partition by calendar_year, calendar_month order by date_value
        )                                                                  as mus_attendance_mtd,
        sum(mem_attendance) over (
            partition by calendar_year, calendar_month order by date_value
        )                                                                  as mem_attendance_mtd,

        -- YTD sums
        sum(ticket_revenue) over (
            partition by calendar_year order by date_value
        )                                                                  as ticket_revenue_ytd,
        sum(tickets_sold) over (
            partition by calendar_year order by date_value
        )                                                                  as tickets_sold_ytd,
        sum(mus_store_gross_profit) over (
            partition by calendar_year order by date_value
        )                                                                  as mus_store_gross_profit_ytd,
        sum(mus_attendance) over (
            partition by calendar_year order by date_value
        )                                                                  as mus_attendance_ytd,
        sum(mem_attendance) over (
            partition by calendar_year order by date_value
        )                                                                  as mem_attendance_ytd

    from fct
)

select
    date_id,
    date_value,
    is_commemoration_day,

    -- ============ ADDITIVE MEASURES (today) ============
    tickets_sold,
    ticket_revenue,
    pass_revenue,
    total_admission_revenue,
    mus_attendance,
    mem_attendance,
    service_fees,
    ticketing_donations,
    box_office_mem_don,
    box_office_mus_exit_don,
    coatcheck_don,
    mask_donations,
    donation_box,
    mus_store_donations,
    mus_exit_donations,
    cart_donation_ask,
    ecom_donation_ask,
    cafe1_donations,
    mus_store_gross_profit,
    retail_carts_gross_profit,
    cafe1_all_profit,
    audio_tour_headset,
    mem_audio_guide_revenue,
    mus_guided_tour_revenue,
    mem_guided_tour_revenue,
    mem_mus_tour_revenue,
    mem_field_trip_revenue,
    mus_field_trip_revenue,
    revealed_tour_revenue,
    ask_educator_revenue,
    virtual_mem_tour_revenue,
    virtual_mus_tour_revenue,
    virtual_yf_mem_tour_revenue,
    mus_guided_tours,
    mem_guided_tours,
    mem_mus_tours,

    -- ============ PERIOD ROLL-UPS (additive) ============
    ticket_revenue_mtd,
    tickets_sold_mtd,
    mus_store_gross_profit_mtd,
    mus_attendance_mtd,
    mem_attendance_mtd,
    ticket_revenue_ytd,
    tickets_sold_ytd,
    mus_store_gross_profit_ytd,
    mus_attendance_ytd,
    mem_attendance_ytd,

    -- ============ NON-ADDITIVE RATIOS (computed here, never re-aggregated) ============
    -- Average ticket price = total admission revenue / tickets sold
    case when tickets_sold = 0 then 0
         else total_admission_revenue / tickets_sold end                   as avg_ticket_price,
        case when tickets_sold_mtd = 0 then 0
             else total_admission_revenue_mtd / tickets_sold_mtd end       as avg_ticket_price_mtd,

    -- Museum store revenue per museum visitor (per-cap)
    case when mus_attendance = 0 then 0
         else mus_store_gross_profit / mus_attendance end                  as mus_store_rev_per_visitor,
    case when mus_attendance_mtd = 0 then 0
         else mus_store_gross_profit_mtd / mus_attendance_mtd end          as mus_store_rev_per_visitor_mtd

from with_periods
order by date_value
