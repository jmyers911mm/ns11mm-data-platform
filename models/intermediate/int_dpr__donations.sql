-- Silver intermediate: Gateway ticketing donations (issued + unissued) and box/exit donations
-- ---------------------------------------------------------------------------
-- Domain: donations
-- Grain: one row per date_key
--
-- Ticketing donations come from the item-journal grain filtered to donation
-- museum categories, PLUS the unissued order book. The box-office memorial
-- donation and museum-exit donation lines are the two specific categories the
-- aggregate ticketing figure EXCLUDES, so they are broken out here.
--
-- Legacy lineage: t_reporting_donations (ticketing portion -- it unions
-- fact_museum_ticketing_donations_issued with
-- fact_museum_ticketing_donations_unissued), t_fact_museum_ticketing_donations_unissued,
-- fact_donations_analysis_report (box_office_mem_don, box_office_mus_exit_don,
-- coatcheck_don).
--
-- Category keys (legacy key_museum_category):
-- 3221 -> box_office_mem_don (DONOPSMEM003 Plaza Box)
-- 3220 -> box_office_mus_exit_don (DONOPSMUS003 Museum Exit Box)
-- 1131,1359,1909 -> excluded from aggregate ticketing donations
-- The category surrogate keys resolve via matrix code; the museum-category
-- integer keys are a legacy 911dw dim_galaxy_items artifact. Where a category
-- integer is unavailable at staging grain, matrix-code proxies are used and
-- flagged for verification (build note: reconcile with Jan-Michael Llanes).
--
-- 8.6.0 (ADR-005 GATED — see DECISION_MEMO.md): the coatcheck / memorial-kiosk
-- donation cohort was missing legacy's zero-quantity filter.
-- t_fact_all_gateway_donations_new reads exactly the two %DON-OPS-MEM% /
-- %DON-OPS-MUS% matrix patterns and ends with `and JNLDetails.Qty <> 0`.
-- Zero-quantity journal detail lines are adjustments, voids and re-postings
-- that carry an amount but no donation event; legacy drops them and the
-- platform did not. The filter is applied to the three cohorts legacy sources
-- from that transformation -- coatcheck_don, box_office_mem_don and
-- box_office_mus_exit_don -- and NOT to the aggregate ticketing_donations
-- cohort, which legacy sources from fact_museum_ticketing_donations_issued
-- and does not filter on quantity.
--
-- SCOPE NOTE (ADR-005 gate, 8.8.0) — owner Chris Wogas:
--  * UNISSUED RECOGNITION. ticketing_donations now includes the unissued leg,
--    matching t_reporting_donations, the DPR-New .prpt (sum(issued) +
--    sum(unissued)) and the Tracker-YTD .prpt. The measure rises. See
--    DECISION_MEMO question 2.
--  * ASYMMETRIC EXCLUSIONS ARE LEGACY, NOT A BUG. The .prpt filters the ISSUED
--    leg with key_museum_category not in (1131,1359,1909,3220,3221) and the
--    UNISSUED leg with not in (1131,1359,1909) -- the box-office and museum-exit
--    categories are carved out of the issued leg only. That asymmetry is
--    preserved: the unissued leg is the whole %MUS% + %DON% cohort, because the
--    legacy unissued fact selects exactly that cohort and nothing narrower.
--  * The quantity <> 0 filter is NOT applied to the unissued leg. It comes from
--    t_fact_all_gateway_donations_new (a journal-side transformation); the
--    unissued fact has its own guard, (d.Quantity - d.IssuedQuantity) > 0,
--    which int_gateway__unissued_order_lines already enforces.
--  * DATE BASIS. The unissued donation leg is keyed on Orders.OpenDate, not on
--    an event date -- that is the legacy basis and it differs from the
--    ticket/tour unissued legs. int_gateway__unissued_order_lines carries the
--    correct one per cohort.

{{ config(materialized='view') }}

with item_lines as (
    select * from {{ ref('int_gateway__item_journal_lines') }}
),

unissued_lines as (
    select * from {{ ref('int_gateway__unissued_order_lines') }}
    where cohort = 'ticketing_donations'
),

donations as (
    select
        date_key,

        -- Aggregate ticketing donations: museum+donation matrix, excluding the
        -- box/exit/special categories handled separately.
        sum(case
              when matrix_code like '%MUS%' and matrix_code like '%DON%'
               and matrix_code not like '%OPS-MEM%'
               and matrix_code not like '%OPS-MUS%'
               -- Member-desk donations excluded per legacy spec (booked to
               -- Membership, not DPR ticketing donations). Added 2026-07-08.
               and plu <> 'DONMBRMUS001'
              then amount else 0 end)                                       as ticketing_donations_issued,

        -- Box office memorial plaza donation (DONOPSMEM003).
        -- quantity <> 0: legacy t_fact_all_gateway_donations_new.
        sum(case when plu = 'DONOPSMEM003' and coalesce(quantity, 0) <> 0
                 then amount else 0 end)                                   as box_office_mem_don,

        -- Museum exit box donation (DONOPSMUS003).
        -- quantity <> 0: legacy t_fact_all_gateway_donations_new.
        sum(case when plu = 'DONOPSMUS003' and coalesce(quantity, 0) <> 0
                 then amount else 0 end)                                   as box_office_mus_exit_don,

        -- Coatcheck donations (matrix like %DON-OPS-MUS%)
        -- Excludes DONOPSMUS003: that PLU is box_office_mus_exit_don above, and
        -- its matrix also matches %DON-OPS-MUS%. Before the staging plu trim the
        -- exit-box dollars silently landed here (exact-equality filter dead);
        -- with the trim both filters fire, so exclude it to avoid double-count.
        -- quantity <> 0: legacy t_fact_all_gateway_donations_new ends its
        -- kiosk/coatcheck cohort with `and JNLDetails.Qty <> 0`.
        sum(case when matrix_code like '%DON-OPS-MUS%'
                  and plu <> 'DONOPSMUS003'
                  and coalesce(quantity, 0) <> 0
                 then amount else 0 end)                                    as coatcheck_don

        -- mask_donations and donation_box moved to int_dpr__retail 2026-07-08:
        -- legacy sources them from CounterPoint retail (items 200704 / 101165),
        -- not the Gateway item journal. See int_dpr__retail.

    from item_lines
    group by date_key
),

unissued as (
    -- Whole %MUS% + %DON% cohort, per the legacy unissued fact. Member-desk
    -- donations are excluded on the same basis as the issued leg so the one
    -- documented platform carve-out stays consistent across both legs.
    select
        date_key,
        sum(case when plu <> 'DONMBRMUS001' then amt_unissued else 0 end)    as ticketing_donations_unissued,
        sum(case when plu <> 'DONMBRMUS001' then qty_unissued else 0 end)    as unissued_donation_qty
    from unissued_lines
    group by date_key
),

date_spine as (
    select date_key from donations
    union select date_key from unissued
)

select
    s.date_key,
    coalesce(d.ticketing_donations_issued, 0)
      + coalesce(u.ticketing_donations_unissued, 0)                          as ticketing_donations,
    coalesce(d.box_office_mem_don, 0)                                        as box_office_mem_don,
    coalesce(d.box_office_mus_exit_don, 0)                                   as box_office_mus_exit_don,
    coalesce(d.coatcheck_don, 0)                                             as coatcheck_don,

    -- Audit companions (8.8.0): the two legs of the recognition change.
    coalesce(d.ticketing_donations_issued, 0)                                as ticketing_donations_issued,
    coalesce(u.ticketing_donations_unissued, 0)                              as ticketing_donations_unissued,
    coalesce(u.unissued_donation_qty, 0)                                     as unissued_donation_qty
from date_spine s
left join donations d on s.date_key = d.date_key
left join unissued  u on s.date_key = u.date_key
