-- Marts report: DPR Excel Data export (flat day-grain actual+budget table)
-- ---------------------------------------------------------------------------
-- Domain: DPR / cross-domain
-- Grain:  one row per report_date
--
-- The "DPR Excel Data" workbook: a flat day-grain export, one column per
-- measure, actual paired with budget where a budget exists. Column names and
-- order follow the workbook so a Power BI table visual (or a paginated export)
-- reproduces it directly.
--
-- Sources: rpt_dpr_powerbi (actuals), rpt_dpr_budget_daily (budget),
-- rpt_dpr_retail_conform (the area REVENUE columns — the workbook prints
-- store / carts / ecommerce / cafe REVENUE here, whereas the MTD/YTD and daily
-- reports print gross PROFIT; that distinction is why the conform carries both
-- net_sales and net_profit).
--
-- TWO COLUMNS ARE DELIBERATELY NULL — 'Total Museum Revenue' and 'Total
-- Memorial Revenue'. Splitting earned revenue between the memorial and the
-- museum is the SAME open business rule that blocks the YTD Tracker's revenue
-- split (ADR-005, pending Data & AI Committee). Emitting a guess here would
-- put an unratified number into a finance-facing export, so the columns are
-- typed NULL with this note. They light up with no report change once the rule
-- lands.
--
-- Museum / Memorial Donations: the workbook prints two donation composites.
-- These are the DPR's authored TOTAL_MUSEUM_DONATIONS / TOTAL_MEMORIAL_DONATIONS
-- line items rather than a new sum — but neither is projected on the DPR
-- wrapper today, so they are carried NULL here and flagged in the release
-- notes as the one wrapper addition this export still needs. Do NOT re-author
-- the composites locally: add the semantic-view metrics to the wrapper.
--
-- ADR-018 note: rpt-from-rpt is the sanctioned projection-chain exception.
-- ADR-004: all business logic in dbt, never Power BI.

{{ config(materialized='view', grants={'select': ['POWERBI_ROLE']}) }}

with a as (
    select * from {{ ref('rpt_dpr_powerbi') }}
),

b as (
    select * from {{ ref('rpt_dpr_budget_daily') }}
),

rc as (
    select * from {{ ref('rpt_dpr_retail_conform') }}
),

spine as (
    select report_date from a
    union
    select report_date from b
)

select
    s.report_date                               as "Date",

    a.memorial_attendance                       as "Memorial Attendance",
    b.memorial_attendance                       as "Memorial Attendance - Budget",
    a.museum_attendance                         as "Museum Attendance",
    b.museum_attendance                         as "Museum Attendance - Budget",
    a.tickets_sold                              as "Tickets Sold",
    b.tickets_sold                              as "Tickets Sold - Budget",
    a.ticket_revenue                            as "Ticket Revenue",
    b.ticket_revenue                            as "Ticket Revenue - Budget",

    -- area REVENUE (not gross profit) per the workbook
    rc.mus_store_net_sales                      as "Museum Store Revenue",
    cast(null as number(38,4))                  as "Museum Store Revenue - Budget",
    rc.carts_net_sales                          as "Retail Carts Revenue",
    cast(null as number(38,4))                  as "Retail Carts Revenue - Budget",
    rc.ecom_net_sales                           as "Ecommerce Revenue",
    cast(null as number(38,4))                  as "Ecommerce Revenue - Budget",

    -- donation composites: see header — wrapper addition still needed
    cast(null as number(38,4))                  as "Museum Donations",
    cast(null as number(38,4))                  as "Memorial Donations",

    a.mus_guided_tour_revenue                   as "Museum Guided Tour Revenue",
    a.virtual_mem_tour_revenue                  as "Memorial Virtual Tour Revenue",
    a.virtual_mus_tour_revenue                  as "Museum Virtual Tour Revenue",
    a.mem_field_trip_revenue                    as "Memorial Field Trip Revenue",
    a.mus_field_trip_revenue                    as "Museum Field Trip Revenue",
    a.revealed_tour_revenue                     as "Revealed Tour Revenue",
    a.ask_educator_revenue                      as "Ask Educator Revenue",

    a.audio_tour_headset                        as "Museum Audio Tour Revenue",
    b.audio_tour_headset                        as "Museum Audio Tour Revenue - Budget",
    rc.cafe_net_sales                           as "Cafe Revenue",

    -- ADR-005 open business rule (see header)
    cast(null as number(38,4))                  as "Total Museum Revenue",
    cast(null as number(38,4))                  as "Total Memorial Revenue"

from spine s
left join a  on s.report_date = a.report_date
left join b  on s.report_date = b.report_date
left join rc on s.report_date = rc.report_date
