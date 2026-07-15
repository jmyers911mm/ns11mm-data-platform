{{ config(materialized='view') }}

-- Marts report: Memorial Museum Daily Tracker - YTD
-- ---------------------------------------------------------------------------
-- Domain: DPR / cross-domain
-- Grain:  one row per date_key
--
-- Presentation view for report.memorial_museum_daily_tracker_ytd. This report
-- is a YTD actuals-vs-budget variance tracker built almost entirely on
-- fct_daily_performance measures (attendance, tour/pass/ticket revenue, retail
-- profit, and every donation line) plus civic_programs. It surfaces the day
-- value, the fiscal-YTD cumulative, the YTD budget, and the variance.
--
-- YTD is computed on demand with a windowed cumulative sum partitioned by
-- fiscal_year (never materialized per period), mirroring the DPR rpt_ pattern.
-- Budget columns are joined from the retail/DPR budget stub and are NULL until
-- the budget source is staged (ADR-005), so every *_variance is currently the
-- actual (budget treated as 0). civic_programs is a placeholder measure until
-- its source is wired (Excel + the Gateway 'Civic Engagement Program Fee').
-- ADR-004: no logic in Power BI.

with fct as (
    select
        f.date_id                                  as date_key,
        f.date_value,
        dd.fiscal_year,
        dd.is_commemoration_day,

        -- Attendance
        f.mem_attendance,
        f.mus_attendance,

        -- Revenue lines
        f.ticket_revenue,
        f.pass_revenue,
        f.mus_guided_tour_revenue,
        f.mem_mus_tour_revenue,
        f.service_fees,
        f.audio_tour_headset,
        f.mem_audio_guide_revenue,

        -- Retail profit
        f.mus_store_gross_profit,
        f.retail_carts_gross_profit,
        f.cafe1_all_profit,

        -- Donation lines
        f.ticketing_donations,
        f.coatcheck_don,
        f.mus_exit_donations,
        f.cart_donation_ask,
        f.mus_store_donations,
        f.donation_box,
        f.mask_donations,
        -- cafe1_donations: not surfaced in fct_daily_performance yet; add to
        -- fct then reinstate here (tracked as a follow-up)

        cast(null as number)                            as civic_programs   -- source pending
    from {{ ref('fct_daily_performance') }} f
    inner join {{ ref('dim_date') }} dd on f.date_id = dd.date_id
),

with_ytd as (
    select
        *,
        -- Fiscal-YTD cumulative on the headline tracked measures
        sum(mem_attendance)          over (partition by fiscal_year order by date_value) as mem_attendance_ytd,
        sum(mus_attendance)          over (partition by fiscal_year order by date_value) as mus_attendance_ytd,
        sum(ticket_revenue)          over (partition by fiscal_year order by date_value) as ticket_revenue_ytd,
        sum(pass_revenue)            over (partition by fiscal_year order by date_value) as pass_revenue_ytd,
        sum(mus_store_gross_profit)  over (partition by fiscal_year order by date_value) as mus_store_gross_profit_ytd,
        sum(retail_carts_gross_profit) over (partition by fiscal_year order by date_value) as retail_carts_gross_profit_ytd,
        sum(cafe1_all_profit)        over (partition by fiscal_year order by date_value) as cafe1_profit_ytd,
        sum(service_fees)            over (partition by fiscal_year order by date_value) as service_fees_ytd,
        sum(audio_tour_headset)      over (partition by fiscal_year order by date_value) as audio_tour_headset_ytd,
        sum(ticketing_donations + coatcheck_don + mus_exit_donations + cart_donation_ask
            + mus_store_donations + donation_box + mask_donations)
            over (partition by fiscal_year order by date_value)                          as total_donations_ytd
    from fct
)

select * from with_ytd