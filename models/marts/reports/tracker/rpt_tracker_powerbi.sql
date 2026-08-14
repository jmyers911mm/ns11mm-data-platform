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
-- NOTE: total_earned_revenue is the DPR TOTAL_ESTIMATED_REVENUE composite. As
-- of 8.1.0 it is no longer re-summed here: the composite is a semantic-view
-- metric (DPR.sv.yaml TOTAL_ESTIMATED_REVENUE) and this model projects it off
-- rpt_dpr_powerbi. Before 8.1.0 the same component set was written out by hand
-- in three places — here, in rpt_dpr_report_long, and (with a different
-- component set) in rpt_dpr_mtd_ytd_long — which ADR-021 calls a defect even
-- when the copies agree; the header comment claiming this one "mirrors the DPR
-- composite exactly" was precisely the kind of claim that quietly stops being
-- true. The individual donation components stay projected below because the
-- Tracker prints them as lines.
--
-- ADR-004: all business logic in dbt, never Power BI.
-- ADR-021: composites authored once.

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

    -- Governed donation composites (semantic-view metrics), carried so the
    -- Tracker's donation sub-totals and the DPR's cannot drift apart.
    total_memorial_donations,
    total_museum_donations,

    -- Total Earned Revenue: the governed DPR TOTAL_ESTIMATED_REVENUE metric,
    -- projected, not re-summed. rpt_tracker_report_long and
    -- rpt_tracker_narrative_brief consume this column unchanged.
    total_estimated_revenue                                as total_earned_revenue
from {{ ref('rpt_dpr_powerbi') }}
