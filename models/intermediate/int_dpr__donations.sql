-- Silver intermediate: Gateway ticketing donations (issued) and box/exit donations
-- ---------------------------------------------------------------------------
-- Domain: donations
-- Grain: one row per date_key
--
-- Ticketing donations come from the item-journal grain filtered to donation
-- museum categories. The box-office memorial donation and museum-exit
-- donation lines are the two specific categories the aggregate ticketing
-- figure EXCLUDES, so they are broken out here.
--
-- Legacy lineage: t_reporting_donations (ticketing portion),
-- fact_museum_ticketing_donations_issued, fact_donations_analysis_report
-- (box_office_mem_don, box_office_mus_exit_don, coatcheck_don).
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

{{ config(materialized='view') }}

with item_lines as (
    select * from {{ ref('int_gateway__item_journal_lines') }}
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
              then amount else 0 end)                                       as ticketing_donations,

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
)

select * from donations