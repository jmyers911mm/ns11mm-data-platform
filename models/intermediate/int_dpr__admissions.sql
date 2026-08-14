-- Silver intermediate: general-admission tickets sold, ticket revenue, pass revenue
-- ---------------------------------------------------------------------------
-- Domain: admissions
-- Grain: one row per date_key
--
-- The GA cohort (ga_flag = 1) drives tickets_sold and ticket_revenue. Pass
-- revenue (CityPASS / C3 / third-party resellers) is a separate set of cohorts,
-- five in legacy, keyed by matrix code, PLU and transaction customer.
--
-- Legacy lineage: t_reporting_tickets_sold_issued_new,
-- t_reporting_ticket_revenue_new, t_reporting_pass_revenue_new,
-- fact_museum_tickets_issued_fordate_new,
-- fact_museum_citypass, fact_museum_citypass_booklets,
-- fact_museum_citypass_scanchange, fact_additional_revenue_new.
--
-- SCOPE NOTE (ADR-005 gate, owner: Chris Wogas / Mary Ng-Zuffante): every
-- change in this file alters what a certified metric counts. It must not ship
-- without sign-off. See DECISION_MEMO.md in this release.
--
-- SCOPE NOTE (ADR-005 gate, 8.7.0): ATTENDANCE MOVED OUT. This model used to
-- publish mus_attendance as the GA ticket QUANTITY. That is a tickets-issued
-- count, not a gate count, and it carried none of the legacy museum-attendance
-- rules. The legacy museum attendance line is t_reporting_mus_attendance --
-- SUM(fact_visitors.passes_scanned) WHERE key_facility IN (1006,3000) with the
-- closed-day zeroing CASE -- which is now authored ONCE in int_dpr__attendance,
-- and fct_daily_performance reads it from there. The GA quantity survives here
-- as mus_attendance_ga_proxy for reconciliation only: it is wired to nothing
-- and must stay that way (composites authored once).
--
-- SCOPE NOTE (unchanged from 7.x): legacy tickets_sold subtracts a child-ticket
-- adjustment from a bulk-tickets feed, which is not staged. This model produces
-- the JOURNAL-ISSUED components, plus typed-NULL placeholders for the unstaged
-- cohorts.
--
-- SCOPE NOTE (ADR-005 gate, 8.8.0): UNISSUED RECOGNITION. tickets_sold and
-- ticket_revenue now include sold-but-not-yet-issued order lines, which is what
-- the legacy DPR does: t_reporting_tickets_sold_issued_new unions "Get Issued
-- Tickets" with "Get Unissued Tickets" and "Get Memorial Tour Mus Admission
-- Unissued tickets" (identical predicates on the issued and unissued facts),
-- and t_reporting_ticket_revenue_new unions "Issued Ticket Revenue" with
-- "Unissued Ticket Revenue". Both measures rise. The unissued leg reuses the
-- SAME exclusion seeds as the issued leg -- the legacy predicates are identical
-- and the lists must not be authored twice. Pass revenue is NOT given an
-- unissued leg: no legacy pass-revenue step reads an unissued fact.
-- See DECISION_MEMO question 2.
--
-- Config-as-data. Four seeds drive the cohorts; edit the seed, not this SQL:
--   seed_gateway_tickets_sold_excluded_plu    tickets sold/issued exclusions
--   seed_gateway_ticket_revenue_excluded_plu  early-access PLUs, revenue only
--   seed_gateway_reseller_customer            resellers routed to pass revenue
--   seed_gateway_pass_plu                     C3 / CityPASS booklet cohorts
-- The %XGA% and %CPA%/%CPB% predicates stay inline: they are pattern matches
-- over an open set of PLUs, not enumerable code lists (CONVENTIONS, CASE
-- classification 2).

{{ config(materialized='view') }}

with ticket_lines as (
    select * from {{ ref('int_gateway__ticket_journal_lines') }}
),

unissued_lines as (
    select * from {{ ref('int_gateway__unissued_order_lines') }}
    where ga_flag = 1
),

tickets_sold_excluded_plu as (
    select plu from {{ ref('seed_gateway_tickets_sold_excluded_plu') }}
),

ticket_revenue_excluded_plu as (
    select plu from {{ ref('seed_gateway_ticket_revenue_excluded_plu') }}
),

reseller_customer as (
    select cast(customer_id as varchar) as customer_id
    from {{ ref('seed_gateway_reseller_customer') }}
),

pass_plu as (
    select plu, pass_cohort, coupon_category
    from {{ ref('seed_gateway_pass_plu') }}
),

-- One labelling pass, so each measure below is a plain conditional aggregate
-- rather than a repeat of the same four sub-selects.
labeled as (
    select
        l.*,
        (tse.plu is not null)                                        as is_tickets_sold_excluded,
        (tre.plu is not null)                                        as is_ticket_revenue_excluded,
        (rc.customer_id is not null)                                 as is_reseller_customer,
        pp.pass_cohort
    from ticket_lines l
    left join tickets_sold_excluded_plu   tse on l.plu = tse.plu
    left join ticket_revenue_excluded_plu tre on l.plu = tre.plu
    left join reseller_customer           rc  on cast(l.customer_id as varchar) = rc.customer_id
    left join pass_plu                    pp  on l.plu = pp.plu
),

-- Same labelling pass over the unissued order lines, against the same seeds.
labeled_unissued as (
    select
        u.*,
        (tse.plu is not null)                                        as is_tickets_sold_excluded,
        (tre.plu is not null)                                        as is_ticket_revenue_excluded
    from unissued_lines u
    left join tickets_sold_excluded_plu   tse on u.plu = tse.plu
    left join ticket_revenue_excluded_plu tre on u.plu = tre.plu
),

ga as (
    select
        date_key,

        -- ── Tickets sold / issued (general admission) ────────────────────────
        -- Legacy t_reporting_tickets_sold_issued_new, "Get Issued Tickets" and
        -- "Get Unissued Tickets" (identical predicates on the two facts):
        --   (account_idno like '%GAD%' or like '%TOU%')
        --   and account_idno not like '%XGA%'
        --   and ga_flag = 1
        --   and plu not in ('CPBOOKYS011','CPBOOKYS010','CPBOOKAD011',
        --                   'CPBOOKAD010','MUSGADEXW001')
        -- account_idno is vAttribute.rItmMatrixCode (t_dim_galaxy_ticket_types),
        -- i.e. this model's matrix_code. The XGA carve-out is applied HERE and
        -- not in gateway_general_admission_flag: legacy's ga_flag CASE carries a
        -- dead literal comparison (`<> '%XGA'`), and the working exclusion is a
        -- cohort filter at this layer. It is NOT applied to ticket revenue --
        -- t_reporting_ticket_revenue_new has no XGA predicate at all.
        sum(case when ga_flag = 1
                  and matrix_code not like '%XGA%'
                  and not is_tickets_sold_excluded
                 then quantity else 0 end)                           as tickets_sold_ga,

        -- ── Ticket revenue (general admission) ───────────────────────────────
        -- Legacy t_reporting_ticket_revenue_new, "Issued Ticket Revenue":
        --   (account_idno like '%GAD%' or like '%TOU%')
        --   and plu not in ('MUSGTOADW004','MUSGTOADB004','MUSGTOADR005')
        --   and customer_id not in ('20056','17522','23110','22361','29619')
        --   and ga_flag = 1
        -- The PLU list is the early-access museum tour, which reports on its own
        -- line; the customer list is the reseller split, whose dollars go to
        -- pass revenue below. customer_id here is JnlTickets.CustomerID.
        sum(case when ga_flag = 1
                  and not is_ticket_revenue_excluded
                  and not is_reseller_customer
                 then amount else 0 end)                             as ticket_revenue_ga,

        -- RECONCILIATION ONLY (8.7.0): the pre-8.7.0 museum attendance value.
        -- Deliberately NOT narrowed by the tickets-sold exclusions, and
        -- deliberately consumed by nothing. Compare against
        -- int_dpr__attendance.mus_attendance to size the tickets-issued vs.
        -- gate-scan gap.
        sum(case when ga_flag = 1 then quantity else 0 end)          as mus_attendance_ga_proxy,

        -- ── Pass revenue cohort 1: CityPASS matrix (pre scan change) ─────────
        -- Legacy "CityPASS Revenue (prior to scan change)":
        --   key_coupon_category in ('None','Adult','Youth')
        --   and (account_idno like '%CPA%' or like '%CPB%')  -> sum(amount)
        -- The coupon-category filter excludes only 'C3 Adult'/'C3 Youth', and
        -- t_fact_museum_citypass assigns those two categories to exactly
        -- CPBOOKAD007 / CPBOOKYS007, so excluding the c3_booklet cohort here is
        -- equivalent and does not need a coupon-category column.
        -- t_fact_museum_citypass also drops a PLU list, carried as
        -- pass_cohort = 'excluded'.
        sum(case when (matrix_code like '%CPA%' or matrix_code like '%CPB%')
                  and coalesce(pass_cohort, '') not in ('c3_booklet', 'citypass_booklet', 'excluded')
                 then quantity else 0 end)                           as pass_tickets_citypass_matrix,
        sum(case when (matrix_code like '%CPA%' or matrix_code like '%CPB%')
                  and coalesce(pass_cohort, '') not in ('c3_booklet', 'citypass_booklet', 'excluded')
                 then amount else 0 end)                             as pass_revenue_citypass_matrix,

        -- ── Pass revenue cohort 2: C3 coupon booklets ───────────────────────
        -- Legacy "C3 Revenue prior to scan change": sum(QUANTITY * AMOUNT), not
        -- sum(amount). The legacy fact stores a per-booklet unit amount, so the
        -- extension is the revenue. This is the only pass cohort that multiplies.
        sum(case when pass_cohort = 'c3_booklet' then quantity else 0 end)
                                                                     as pass_tickets_c3_booklet,
        sum(case when pass_cohort = 'c3_booklet' then quantity * amount else 0 end)
                                                                     as pass_revenue_c3_booklet,

        -- ── Pass revenue cohort 3: CityPASS booklets ────────────────────────
        -- Legacy "CityPASS Booklet revenue" via fact_museum_citypass_booklets:
        -- plu in ('MUSGADADCP005','MUSGADYSCP005') -> sum(amount).
        -- DATE-BASIS DIVERGENCE: the legacy booklet fact keys on
        -- JnlHeaders.fiscalDate; this model keys on the recognized date_key.
        -- Flagged in the decision memo.
        sum(case when pass_cohort = 'citypass_booklet' then quantity else 0 end)
                                                                     as pass_tickets_citypass_booklet,
        sum(case when pass_cohort = 'citypass_booklet' then amount else 0 end)
                                                                     as pass_revenue_citypass_booklet,

        -- ── Pass revenue cohort 4: third-party resellers ────────────────────
        -- Legacy "Other Pass Revenue (Sightseeing, Explorer, New York Pass)" --
        -- the exact mirror of the ticket-revenue predicate with the customer
        -- test inverted. Same PLU exclusion, same ga_flag, IN instead of NOT IN.
        sum(case when ga_flag = 1
                  and not is_ticket_revenue_excluded
                  and is_reseller_customer
                 then quantity else 0 end)                           as pass_tickets_reseller,
        sum(case when ga_flag = 1
                  and not is_ticket_revenue_excluded
                  and is_reseller_customer
                 then amount else 0 end)                             as pass_revenue_reseller

    from labeled
    group by date_key
),

-- ── Unissued leg (8.8.0) ────────────────────────────────────────────────────
-- The legacy unissued steps carry the SAME predicates as the issued steps, so
-- the same seed-driven flags and the same matrix patterns are applied here. The
-- mem_tour_mus_admission cohort is legacy's "Get Memorial Tour Mus Admission
-- Unissued tickets" step (matrix %MGT% and %XXX%), which has no PLU exclusion.
unissued as (
    select
        date_key,
        sum(case when cohort = 'museum_tickets'
                  and (matrix_code like '%GAD%' or matrix_code like '%TOU%')
                  and matrix_code not like '%XGA%'
                  and not is_tickets_sold_excluded
                 then qty_unissued else 0 end)
          + sum(case when cohort = 'mem_tour_mus_admission'
                     then qty_unissued else 0 end)                   as tickets_sold_unissued,
        sum(case when cohort = 'museum_tickets'
                  and (matrix_code like '%GAD%' or matrix_code like '%TOU%')
                  and not is_ticket_revenue_excluded
                 then amt_unissued else 0 end)
          + sum(case when cohort = 'mem_tour_mus_admission'
                     then amt_unissued else 0 end)                   as ticket_revenue_unissued
    from labeled_unissued
    group by date_key
),

date_spine as (
    select date_key from ga
    union select date_key from unissued
)

select
    s.date_key                                                       as date_key,
    coalesce(g.tickets_sold_ga, 0)
      + coalesce(u.tickets_sold_unissued, 0)                         as tickets_sold,
    coalesce(g.ticket_revenue_ga, 0)
      + coalesce(u.ticket_revenue_unissued, 0)                       as ticket_revenue,

    -- Audit companions (8.8.0): the size of the newly-added unissued leg.
    coalesce(u.tickets_sold_unissued, 0)                             as unissued_tickets_sold,
    coalesce(u.ticket_revenue_unissued, 0)                           as unissued_ticket_revenue,

    coalesce(g.mus_attendance_ga_proxy, 0)                           as mus_attendance_ga_proxy,

    -- Pass revenue cohorts, carried individually so the roll-up is auditable
    -- against the five legacy steps rather than being a single opaque number.
    coalesce(g.pass_tickets_citypass_matrix, 0)                         as pass_tickets_citypass_matrix,
    coalesce(g.pass_revenue_citypass_matrix, 0)                         as pass_revenue_citypass_matrix,
    coalesce(g.pass_tickets_c3_booklet, 0)                              as pass_tickets_c3_booklet,
    coalesce(g.pass_revenue_c3_booklet, 0)                              as pass_revenue_c3_booklet,
    coalesce(g.pass_tickets_citypass_booklet, 0)                        as pass_tickets_citypass_booklet,
    coalesce(g.pass_revenue_citypass_booklet, 0)                        as pass_revenue_citypass_booklet,
    coalesce(g.pass_tickets_reseller, 0)                                as pass_tickets_reseller,
    coalesce(g.pass_revenue_reseller, 0)                                as pass_revenue_reseller,

    -- ── Placeholders (ADR-021: typed NULL with a stated cause) ──────────────
    -- Legacy pass-revenue cohort 5: fact_museum_citypass_scanchange, the
    -- post-2016-06-01 CityPASS/C3 scan-change feed, sum(quantity*amount) for
    -- coupon categories Adult / Youth / C3 Adult / C3 Youth.
    -- Cause: NO DATA FEED. The scan-change table is a 911dw fact with no
    -- Gateway-side equivalent in the 21 staged tables and no CounterPoint
    -- source; it has to be re-derived or re-extracted before it can be modelled.
    cast(null as number(38,4))                                       as pass_revenue_scanchange,
    cast(null as number(38,4))                                       as pass_tickets_scanchange,

    -- Legacy pass-revenue cohort 6: fact_additional_revenue_new filtered to
    -- account_idno like '%GAD-NYA-NYA-OTH-XXX%' (New York Pass additional
    -- revenue), plus the sibling 'RESLADDREV001' additional-revenue line that
    -- t_reporting_ticket_revenue_new adds to TICKET revenue.
    -- Cause: NO DATA FEED. fact_additional_revenue_new is loaded from an
    -- operations workbook, not from Galaxy; nothing in staging carries it.
    cast(null as number(38,4))                                       as pass_revenue_additional,
    cast(null as number(38,4))                                       as ticket_revenue_additional,

    -- Legacy tickets-sold child-ticket subtraction:
    --   from fact_museum_bulk_tickets_test where f.pricePointID = 84
    -- Cause: NO DATA FEED. Checked and confirmed absent -- the bulk-tickets fact
    -- is not staged at all, and the only price-point column anywhere in staging
    -- is stg_gateway__vattribute.itm_price_point_id, which is the ITEM master's
    -- price point, not the sold ticket's pricePointID. The column cannot be
    -- reconstructed from what is staged.
    cast(null as number(38,4))                                       as child_tickets_subtracted,

    -- ── Roll-ups ────────────────────────────────────────────────────────────
    -- Total pass revenue over the cohorts that HAVE a feed. The two placeholder
    -- cohorts are excluded from the sum rather than zero-filled into it: a NULL
    -- inside this total would NULL the DPR admission line, and a zero would
    -- assert the cohort is empty. Their absence is the documented gap.
    coalesce(g.pass_tickets_citypass_matrix, 0)
      + coalesce(g.pass_tickets_c3_booklet, 0)
      + coalesce(g.pass_tickets_citypass_booklet, 0)
      + coalesce(g.pass_tickets_reseller, 0)                           as pass_tickets,
    coalesce(g.pass_revenue_citypass_matrix, 0)
      + coalesce(g.pass_revenue_c3_booklet, 0)
      + coalesce(g.pass_revenue_citypass_booklet, 0)
      + coalesce(g.pass_revenue_reseller, 0)                           as pass_revenue
from date_spine s
left join ga       g on s.date_key = g.date_key
left join unissued u on s.date_key = u.date_key
