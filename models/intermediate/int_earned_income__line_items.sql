-- Silver intermediate: earned-income report line items (the earned_revenue_report_values equivalent)
-- ---------------------------------------------------------------------------
-- Domain: earned income
-- Grain:  one row per date_key
--
-- Day-grain component table behind the Earned Income Variance Report. Every
-- printed ACTUAL line is assembled here from the corrected DPR silver chain,
-- component by component, with no quotient and no total that another model
-- already owns. Feeds fct_earned_income, and through it
-- rpt_earned_income_variance_report_long.
--
-- Legacy lineage: 911dw.earned_revenue_report_values, written by
-- t_fact_earned_income_line_items (9 steps), t_fact_dpr_totals and
-- t_fact_operating_expenses_graphs; plus the actual-side halves of
-- t_fact_earned_income_variance_values_table, _revenue_table, _totals_table,
-- _avg_ticket, t_fact_guided_tours_earned_income_variance and
-- t_fact_citypass_c3_earned_income_variance, which all write
-- 911dw.earned_income_report_analysis.
--
-- RE-PROJECTED vs NEW (the line-by-line statement this release owes its reader):
--   RE-PROJECTED from the corrected DPR chain, no new derivation here --
--     museum_attendance          int_dpr__attendance.mus_passes_scanned
--     tickets_ga                 int_dpr__admissions.tickets_sold        (8.8.0 unissued)
--     ticket_revenue_ga          int_dpr__admissions.ticket_revenue      (8.6.0 + 8.8.0)
--     ticket_revenue_reseller    int_dpr__admissions.pass_revenue_reseller (8.6.0)
--     tickets/revenue c3_booklet int_dpr__admissions.pass_*_c3_booklet   (8.6.0)
--     citypass_* matrix/booklet  int_dpr__admissions.pass_*_citypass_*   (8.6.0)
--     service_fees               int_dpr__fees_and_services              (8.6.0 ticket half)
--     mus/mem guided tours+rev   int_dpr__tour_revenue                   (8.8.0 buyout+unissued)
--     early_access_*             int_dpr__tour_revenue                   (8.8.0 NEW actual)
--     youth_fam_*                int_dpr__tour_revenue                   (8.8.0 NEW actual)
--     mem_mus_tours / revenue    int_dpr__fees_and_services
--   NEW in this release (no prior platform home) --
--     the EIV ticket-revenue composite (DPR ticket revenue re-joined to the
--       reseller cohort, because the legacy EIV revenue step has no customer
--       filter and the legacy DPR step does),
--     the EIV citypass composites,
--     the four operating-expense columns (seed contract only, no feed).
--
-- SCOPE NOTE (no ADR-005 gate): every line published here is NEW to the
-- platform. Nothing in this model changes a number the estate already prints.
-- It does inherit the 8.5.0-8.8.0 gates through its inputs -- if those releases
-- are not signed, these numbers move when they are.
--
-- PLACEHOLDERS (ADR-021: typed NULL, stated cause, never zero-filled) --
--   tickets_scanchange_ga, citypass_tickets_scanchange,
--   ticket_revenue_scanchange, citypass_revenue_scanchange
--       cause: NO DATA FEED. 911dw.fact_museum_citypass_scanchange has no
--       Gateway-side equivalent among the staged tables and its construction is
--       not in the captured transformation set (carried from 8.6.0).
--   tickets_bulk_scan, ticket_revenue_bulk_scan, ticket_revenue_bulk_add
--       cause: NO DATA FEED. 911dw.fact_museum_bulk_tickets_test and
--       fact_bulk_tickets_add are not staged.
--   child_evg_tickets
--       cause: NO DATA FEED. The legacy subtraction is
--       fact_museum_bulk_tickets_test WHERE pricePointID = 84; neither the fact
--       nor that column is staged (confirmed in 8.6.0 item 5f).
--   ticket_revenue_nyp_add
--       cause: NO DATA FEED. 911dw.fact_museum_nyp_add is loaded from an
--       operations workbook, not from Galaxy.
--   est_operating_expenses, est_operating_expenses_budget,
--   total_operating_expenses, total_operating_expenses_budget
--       cause: NO DATA FEED. seed_budgeted_expense is an empty seed carrying
--       the contract for the manual workbook that fed
--       911dw.fact_budgeted_expenses. See DECISION_MEMO.md.
--
-- ADR-004: all business logic in dbt, never Power BI.
-- ADR-021 ratio rule: no quotient is stored. Average ticket price is carried as
-- ticket_revenue over tickets and divided once at display grain.

{{ config(materialized='view') }}

with admissions as (
    select * from {{ ref('int_dpr__admissions') }}
),

tours as (
    select * from {{ ref('int_dpr__tour_revenue') }}
),

fees as (
    select * from {{ ref('int_dpr__fees_and_services') }}
),

attendance as (
    select * from {{ ref('int_dpr__attendance') }}
),

-- Manual operating-expense workbook contract. The seed ships with a header and
-- no rows, so every column below is NULL until Finance owns the feed. A left
-- join keeps the day spine intact and keeps the columns typed.
expenses as (
    select
        to_date(key_date::varchar, 'YYYYMMDD')                              as date_key,
        cast(budgeted_expense as number(38, 4))                             as est_operating_expenses,
        cast(budgeted_expense_budget_value as number(38, 4))                as est_operating_expenses_budget,
        cast(budgeted_total_expense as number(38, 4))                       as total_operating_expenses,
        cast(budgeted_total_expense_budget_value as number(38, 4))          as total_operating_expenses_budget
    from {{ ref('seed_budgeted_expense') }}
),

date_spine as (
    select cast(date_key as date) as date_key from admissions where date_key is not null
    union select cast(date_key as date) from tours      where date_key is not null
    union select cast(date_key as date) from fees       where date_key is not null
    union select cast(date_key as date) from attendance where date_key is not null
    union select cast(date_key as date) from expenses   where date_key is not null
),

components as (
    select
        s.date_key,

        -- ── Museum attendance ────────────────────────────────────────────────
        -- Legacy t_fact_earned_income_variance_values_table:
        --   sum(v.passes_scanned) from fact_visitors where key_facility in (1006,3000)
        -- with NO closed-day zeroing. int_dpr__attendance carries both forms;
        -- this report takes the UNZEROED one (mus_passes_scanned), because the
        -- legacy EIV step has no CASE. The DPR line takes the zeroed one. The
        -- two reports therefore differ on roughly one Tuesday a week; that is
        -- legacy behaviour, reproduced deliberately and flagged in NOTES.md.
        att.mus_passes_scanned                                              as museum_attendance,

        -- ── Tickets (the report's "Tickets" line) ────────────────────────────
        -- Legacy: issued + unissued + mem_mus issued + mem_mus unissued
        --         + c3 + c3 scan-change GA + bulk scans - child evergreen.
        -- The first four are int_dpr__admissions.tickets_sold: its GA cohort is
        -- ga_flag = 1 with the %XGA% carve-out and the tickets-sold PLU list, and
        -- its unissued leg carries the mem_tour_mus_admission (%MGT%+%XXX%)
        -- cohort, which is exactly the legacy mem_mus pair.
        coalesce(a.tickets_sold, 0)                                         as tickets_ga,
        coalesce(a.pass_tickets_c3_booklet, 0)                              as tickets_c3_booklet,
        a.pass_tickets_scanchange                                           as tickets_scanchange_ga,
        cast(null as number(38, 4))                                         as tickets_bulk_scan,
        a.child_tickets_subtracted                                          as child_evg_tickets,

        -- ── Ticket revenue (the report's "Revenue" line) ─────────────────────
        -- Legacy: GAD/TOU issued + unissued (less the three early-access PLUs)
        --         + %MGT%/%XXX% issued + unissued + c3 + c3 scan-change
        --         + NYP additional + bulk add + bulk scan.
        -- The legacy EIV revenue step has NO customer_id predicate, while the
        -- legacy DPR ticket-revenue step routes five reseller customers to pass
        -- revenue. int_dpr__admissions implements the DPR form, so the reseller
        -- cohort is added back here to recover the EIV definition. This is the
        -- single place the two definitions are reconciled.
        coalesce(a.ticket_revenue, 0)                                       as ticket_revenue_ga,
        coalesce(a.pass_revenue_reseller, 0)                                as ticket_revenue_reseller,
        coalesce(a.pass_revenue_c3_booklet, 0)                              as ticket_revenue_c3_booklet,
        a.pass_revenue_scanchange                                           as ticket_revenue_scanchange,
        a.pass_revenue_additional                                           as ticket_revenue_nyp_add,
        cast(null as number(38, 4))                                         as ticket_revenue_bulk_add,
        cast(null as number(38, 4))                                         as ticket_revenue_bulk_scan,

        -- ── Service fees ────────────────────────────────────────────────────
        -- Legacy EIV sums the museum (%MUF%+%FEE%) and memorial (%MEF%+%FEE%)
        -- steps, which is int_dpr__fees_and_services.service_fees after 8.6.0
        -- added the ticket-line half of the museum step.
        coalesce(f.service_fees, 0)                                         as service_fees,
        coalesce(f.museum_service_fees, 0)                                  as museum_service_fees,
        coalesce(f.memorial_service_fees, 0)                                as memorial_service_fees,

        -- ── CityPASS ────────────────────────────────────────────────────────
        -- Legacy tickets: %CPA%/%CPB% matrix quantity + scan-change (Adult/Youth).
        -- Legacy revenue: %CPA%/%CPB% matrix amount (coupon 'None') plus
        --                 quantity*amount (coupon Adult/Youth), + scan-change,
        --                 + the two booklet PLUs.
        -- DELIBERATE DIVERGENCE 1: the C3 booklet cohort is counted on the
        -- TICKETS line above and NOT here. Legacy's matrix predicate carries no
        -- coupon-category carve-out, so if CPBOOKAD007 / CPBOOKYS007 carry a
        -- CPA/CPB matrix code the legacy total counts them twice (once as
        -- citypass_tickets, once as c3_tickets). Revenue already keeps them
        -- apart in legacy; tickets are made symmetric here rather than
        -- reproducing a suspected double count. Verification query in NOTES.md.
        -- DELIBERATE DIVERGENCE 2: the Adult/Youth quantity*amount extension
        -- cannot be reproduced. key_coupon_category is not staged, so the matrix
        -- cohort is sum(amount) throughout. Cause: PENDING AN UPSTREAM ADDITION.
        -- CITYPASS_REVENUE is 'Partial' in the layout seed for exactly this.
        coalesce(a.pass_tickets_citypass_matrix, 0)                         as citypass_tickets_matrix,
        coalesce(a.pass_tickets_citypass_booklet, 0)                        as citypass_tickets_booklet,
        a.pass_tickets_scanchange                                           as citypass_tickets_scanchange,
        coalesce(a.pass_revenue_citypass_matrix, 0)                         as citypass_revenue_matrix,
        coalesce(a.pass_revenue_citypass_booklet, 0)                        as citypass_revenue_booklet,
        a.pass_revenue_scanchange                                           as citypass_revenue_scanchange,

        -- ── Guided tours ────────────────────────────────────────────────────
        -- All four lines are re-projected wholesale from int_dpr__tour_revenue,
        -- which after 8.8.0 is issued + unissued + buyout with the legacy
        -- quantity suppression. Legacy EIV adds the museum buyout quantity a
        -- SECOND time (guided_tours = total_mus_tours + mus_gt_buyout_qty, where
        -- total_mus_tours already contains buyout_qty). That double count is not
        -- reproduced; see NOTES.md and DECISION_MEMO.md.
        coalesce(t.mus_guided_tours, 0)                                     as mus_guided_tours,
        coalesce(t.mus_guided_tour_revenue, 0)                              as mus_guided_tour_revenue,
        coalesce(t.mem_guided_tours, 0)                                     as mem_guided_tours,
        coalesce(t.mem_guided_tour_revenue, 0)                              as mem_guided_tour_revenue,
        coalesce(t.early_access_tours, 0)                                   as early_access_tours,
        coalesce(t.early_access_tour_revenue, 0)                            as early_access_tour_revenue,
        coalesce(t.youth_fam_tours, 0)                                      as youth_fam_tours,
        coalesce(t.youth_fam_tour_revenue, 0)                               as youth_fam_tour_revenue,
        coalesce(f.mem_mus_tours, 0)                                        as mem_mus_tours,
        coalesce(f.mem_mus_tour_revenue, 0)                                 as mem_mus_tour_revenue,

        -- ── Operating expenses (no feed; see header) ────────────────────────
        e.est_operating_expenses,
        e.est_operating_expenses_budget,
        e.total_operating_expenses,
        e.total_operating_expenses_budget

    from date_spine s
    left join admissions a   on s.date_key = cast(a.date_key as date)
    left join tours      t   on s.date_key = cast(t.date_key as date)
    left join fees       f   on s.date_key = cast(f.date_key as date)
    left join attendance att on s.date_key = cast(att.date_key as date)
    left join expenses   e   on s.date_key = e.date_key
)

select
    date_key,
    museum_attendance,

    -- Roll-ups over the components that HAVE a feed. The placeholder components
    -- are excluded from every sum rather than zero-filled into it: a NULL inside
    -- these totals would blank the whole report line, and a zero would assert
    -- the cohort is empty. Their absence is the documented gap and the reason
    -- TICKETS / TICKET_REVENUE are 'Partial' in the layout seed.
    tickets_ga + tickets_c3_booklet                                         as tickets,
    tickets_ga,
    tickets_c3_booklet,
    tickets_scanchange_ga,
    tickets_bulk_scan,
    child_evg_tickets,

    ticket_revenue_ga + ticket_revenue_reseller + ticket_revenue_c3_booklet as ticket_revenue,
    ticket_revenue_ga,
    ticket_revenue_reseller,
    ticket_revenue_c3_booklet,
    ticket_revenue_scanchange,
    ticket_revenue_nyp_add,
    ticket_revenue_bulk_add,
    ticket_revenue_bulk_scan,

    service_fees,
    museum_service_fees,
    memorial_service_fees,

    citypass_tickets_matrix + citypass_tickets_booklet                      as citypass_tickets,
    citypass_tickets_matrix,
    citypass_tickets_booklet,
    citypass_tickets_scanchange,

    citypass_revenue_matrix + citypass_revenue_booklet                      as citypass_revenue,
    citypass_revenue_matrix,
    citypass_revenue_booklet,
    citypass_revenue_scanchange,

    mus_guided_tours,
    mus_guided_tour_revenue,
    mem_guided_tours,
    mem_guided_tour_revenue,
    early_access_tours,
    early_access_tour_revenue,
    youth_fam_tours,
    youth_fam_tour_revenue,
    mem_mus_tours,
    mem_mus_tour_revenue,

    est_operating_expenses,
    est_operating_expenses_budget,
    total_operating_expenses,
    total_operating_expenses_budget
from components
