-- Marts fact: earned income actuals (additive measures, one row per day)
-- ---------------------------------------------------------------------------
-- Domain: earned income
-- Grain:  one row per date_key
--
-- Day-grain ACTUAL side of the Earned Income Variance Report. Projects
-- int_earned_income__line_items onto the conformed date key and carries every
-- printed line plus the component detail behind it, so each report line can be
-- audited against its legacy step without re-deriving anything. Feeds
-- rpt_earned_income_variance_report_long and, through it, the Power BI Earned
-- Income Variance matrix and the narrative brief.
--
-- Replaces the actual columns of legacy 911dw.earned_income_report_analysis
-- (written by six transformations) and 911dw.earned_revenue_report_values
-- (written by three). The legacy *_diff columns are NOT stored: variance is
-- actual minus budget at display grain, resolved in the serving shape.
--
-- Legacy lineage: t_fact_earned_income_variance_values_table,
-- t_fact_earned_income_variance_revenue_table,
-- t_fact_earned_income_variance_totals_table,
-- t_fact_earned_income_variance_avg_ticket,
-- t_fact_guided_tours_earned_income_variance,
-- t_fact_citypass_c3_earned_income_variance, t_fact_earned_income_line_items,
-- t_fact_operating_expenses_graphs.
--
-- NOTE: the two report composites (Total Tickets Sold, Total Admissions
-- Revenue) are deliberately NOT columns here. Legacy defines each as a sum of
-- lines this fact already carries -- total_tickets_sold = tickets + citypass
-- tickets, total_admissions_rev = ticket revenue + citypass revenue + service
-- fees -- so storing them would be the same total authored twice. They are
-- resolved once, in rpt_earned_income_variance_report_long, from the carried
-- components. Average ticket price likewise stays a numerator/denominator pair
-- (ADR-021 ratio rule).
--
-- NOTE: Total Estimated Revenue is NOT built here. The legacy EIV variant
-- (t_fact_dpr_totals) differs from the DPR's in three named ways and the DPR
-- semantic view already owns a metric of that name. See NOTES.md section 5.
--
-- STATUS: the four operating-expense columns are typed NULLs -- cause NO DATA
-- FEED. They read seed_budgeted_expense, which ships as a header-only contract
-- for the manual workbook that fed 911dw.fact_budgeted_expenses. Owner of the
-- open question: Mike Cartier's team (see DECISION_MEMO.md). Do not add a
-- not_null test to these four and do not coalesce them to zero.
--
-- ADR-004: all business logic in dbt, never Power BI.

{{ config(
    materialized='table',
    cluster_by=['date_key']
) }}

with line_items as (
    select * from {{ ref('int_earned_income__line_items') }}
),

final as (
    select
        dd.date_key,
        l.date_key                                                          as date_value,
        dd.is_commemoration_day,

        -- Attendance (unzeroed passes scanned; see int_earned_income__line_items)
        l.museum_attendance,

        -- Tickets and their components
        l.tickets,
        l.tickets_ga,
        l.tickets_c3_booklet,
        l.tickets_scanchange_ga,
        l.tickets_bulk_scan,
        l.child_evg_tickets,

        -- Ticket revenue and its components
        l.ticket_revenue,
        l.ticket_revenue_ga,
        l.ticket_revenue_reseller,
        l.ticket_revenue_c3_booklet,
        l.ticket_revenue_scanchange,
        l.ticket_revenue_nyp_add,
        l.ticket_revenue_bulk_add,
        l.ticket_revenue_bulk_scan,

        -- Service fees
        l.service_fees,
        l.museum_service_fees,
        l.memorial_service_fees,

        -- CityPASS
        l.citypass_tickets,
        l.citypass_tickets_matrix,
        l.citypass_tickets_booklet,
        l.citypass_tickets_scanchange,
        l.citypass_revenue,
        l.citypass_revenue_matrix,
        l.citypass_revenue_booklet,
        l.citypass_revenue_scanchange,

        -- Tours
        l.mus_guided_tours,
        l.mus_guided_tour_revenue,
        l.mem_guided_tours,
        l.mem_guided_tour_revenue,
        l.early_access_tours,
        l.early_access_tour_revenue,
        l.youth_fam_tours,
        l.youth_fam_tour_revenue,
        l.mem_mus_tours,
        l.mem_mus_tour_revenue,

        -- Operating expenses. The BUDGET values arrive on the same row as the
        -- actuals because the legacy feed is one manual workbook carrying both
        -- scenarios (911dw.fact_budgeted_expenses). This is the only budget
        -- value in an actuals fact anywhere in the estate and it is deliberate:
        -- inventing a separate budget fact for a source that does not split
        -- would be a fiction. rpt_earned_income_variance_budget_daily reads the
        -- two _budget columns back out so the serving shape still has exactly
        -- one budget source.
        l.est_operating_expenses,
        l.est_operating_expenses_budget,
        l.total_operating_expenses,
        l.total_operating_expenses_budget

    from line_items l
    inner join {{ ref('dim_date') }} dd
        on cast(l.date_key as date) = dd.date_key
)

select * from final
