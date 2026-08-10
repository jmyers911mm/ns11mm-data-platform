-- Marts report: day-grain Tracker actuals conform over rpt_dpr_powerbi (Memorial & Museum Daily Tracker YTD)
-- ---------------------------------------------------------------------------
-- Domain: DPR / cross-domain
-- Grain:  one row per report_date
--
-- Day-grain ACTUALS for the Memorial & Museum Daily Tracker (YTD): a thin
-- projection of rpt_dpr_powerbi carrying attendance, tickets sold, and every
-- additive earned-revenue component. Built on the existing DPR wrapper — the
-- sanctioned rpt -> rpt projection-chain exception (same as
-- rpt_dpr_report_long) — so no new SEMANTIC_VIEW() call and no duplicated
-- metric logic. Feeds the Power BI Tracker dataset (the weekday x week-bucket
-- attendance matrix reads this directly via Dim_Date; YTD is a DAX time-
-- intelligence roll-up, never materialized), rpt_tracker_report_long, and
-- rpt_tracker_narrative_brief.
-- NOTE: the Total Earned Revenue composite is summed in DAX from the
-- components carried here; it mirrors the DPR TOTAL_ESTIMATED_REVENUE
-- composite exactly (see rpt_dpr_report_long). Component set:
--   admission_revenue
--   + revealed_tour_revenue + mem_mus_tour_revenue + mus_guided_tour_revenue
--     + mem_guided_tour_revenue + virtual_tour_revenue
--   + mus_store_gross_profit + retail_carts_gross_profit
--   + cafe_profit + audio_tour_headset
--   + cart_donation_ask + box_office_mem_don + donation_box + ecom_donation_ask
--   + ticketing_donations + box_office_mus_exit_don + coatcheck_don
--     + mus_store_don + mus_exit_don + cafe_don
--
-- ADR-004: all business logic in dbt, never Power BI.

{{ config(materialized='view', grants={'select': ['POWERBI_ROLE']}) }}

select
    report_date,

    -- attendance & tickets
    memorial_attendance,
    museum_attendance,
    tickets_sold,

    -- admissions
    admission_revenue,

    -- tours
    revealed_tour_revenue,
    mem_mus_tour_revenue,
    mus_guided_tour_revenue,
    mem_guided_tour_revenue,
    virtual_tour_revenue,

    -- retail & cafe
    mus_store_gross_profit,
    retail_carts_gross_profit,
    cafe_profit,

    -- audio
    audio_tour_headset,

    -- donation components
    cart_donation_ask,
    box_office_mem_don,
    donation_box,
    ecom_donation_ask,
    ticketing_donations,
    box_office_mus_exit_don,
    coatcheck_don,
    mus_store_don,
    mus_exit_don,
    cafe_don,

    -- Total Earned Revenue composite (7.12.1): authored HERE, once — the DPR
    -- TOTAL_ESTIMATED_REVENUE component set. rpt_tracker_report_long and
    -- rpt_tracker_narrative_brief consume this column; do not re-author the
    -- sum downstream (define once, serve many). NULL components are treated
    -- as zero so one missing feed does not NULL the composite.
    coalesce(admission_revenue, 0)
      + coalesce(revealed_tour_revenue, 0) + coalesce(mem_mus_tour_revenue, 0)
      + coalesce(mus_guided_tour_revenue, 0) + coalesce(mem_guided_tour_revenue, 0)
      + coalesce(virtual_tour_revenue, 0)
      + coalesce(mus_store_gross_profit, 0) + coalesce(retail_carts_gross_profit, 0)
      + coalesce(cafe_profit, 0) + coalesce(audio_tour_headset, 0)
      + coalesce(cart_donation_ask, 0) + coalesce(box_office_mem_don, 0)
      + coalesce(donation_box, 0) + coalesce(ecom_donation_ask, 0)
      + coalesce(ticketing_donations, 0) + coalesce(box_office_mus_exit_don, 0)
      + coalesce(coatcheck_don, 0) + coalesce(mus_store_don, 0)
      + coalesce(mus_exit_don, 0) + coalesce(cafe_don, 0)   as total_earned_revenue
from {{ ref('rpt_dpr_powerbi') }}
