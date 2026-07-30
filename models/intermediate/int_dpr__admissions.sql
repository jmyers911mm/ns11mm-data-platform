-- Silver intermediate: general-admission tickets sold, ticket revenue, attendance
-- ---------------------------------------------------------------------------
-- Domain: admissions
-- Grain: one row per date_key
--
-- The GA cohort (ga_flag = 1) drives tickets_sold, ticket_revenue and the
-- Galaxy-scanned museum attendance proxy. Pass revenue (CityPASS/C3) is a
-- separate cohort keyed by matrix codes CPA/CPB.
--
-- Legacy lineage: t_reporting_tickets_sold_issued_new,
-- t_reporting_ticket_revenue_new, t_reporting_pass_revenue_new,
-- t_reporting_mus_attendance, fact_museum_tickets_issued_fordate_new,
-- fact_museum_citypass, fact_museum_citypass_scanchange.
--
-- SCOPE NOTE (ADR-005 gate): the legacy tickets_sold subtracts "child
-- tickets" and bulk-scan adjustments, and legacy mus_attendance blends
-- Sensource turnstile counts (sensordata) with scanned GA passes. Those
-- inputs are NOT in the 21 staged tables (no Sensource, no bulk-tickets
-- feed, no CityPASS actuals spreadsheet). This model therefore produces the
-- SCANNED-GA and JOURNAL-REVENUE components only. The additional-revenue
-- and Sensource blend must be layered in once those sources are staged.
-- Flagged for the ADR-005 metric workshop with Chris Wogas.

{{ config(materialized='view') }}

with ticket_lines as (
    select * from {{ ref('int_gateway__ticket_journal_lines') }}
),

ga as (
    select
        date_key,
        -- Tickets sold / issued (general admission)
        sum(case when ga_flag = 1 then quantity else 0 end)                as tickets_sold_ga,
        sum(case when ga_flag = 1 then amount else 0 end)                  as ticket_revenue_ga,

        -- Scanned GA quantity as an attendance proxy (partial; see scope note)
        sum(case when ga_flag = 1 then quantity else 0 end)                as mus_attendance_scanned_ga,

        -- CityPASS / C3 pass revenue (matrix CPA / CPB)
        sum(case when matrix_code like '%CPA%' or matrix_code like '%CPB%'
                 then quantity else 0 end)                                  as pass_tickets,
        sum(case when matrix_code like '%CPA%' or matrix_code like '%CPB%'
                 then amount else 0 end)                                    as pass_revenue

    from ticket_lines
    group by date_key
)

select
    date_key,
    tickets_sold_ga                                                        as tickets_sold,
    ticket_revenue_ga                                                      as ticket_revenue,
    mus_attendance_scanned_ga                                             as mus_attendance,
    pass_tickets,
    pass_revenue
from ga
