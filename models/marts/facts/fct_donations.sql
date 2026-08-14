-- Marts fact: daily donations and their visitor denominators (one row per day)
-- ---------------------------------------------------------------------------
-- Domain: donations
-- Grain: one row per date_key
--
-- Replaces legacy 911dw.fact_donations_analysis_report. Pivots
-- int_donations__all_sources from component grain to the legacy column shape
-- and joins the four Sensource visitor / attendance denominators the report's
-- per-visitor ratios divide by. Feeds rpt_donations_report_long (the Donations
-- Analysis Report serving shape) AND -- independently of that report surface --
-- the five already-migrated live reports that read the legacy table directly:
-- DPR-New, DPR-MTD, DPR-YTD, Tracker-YTD and Retail Performance. That is why
-- the column NAMES here are the legacy ones rather than platform-idiomatic
-- ones: the table is a binding contract, not just a report input.
--
-- Legacy lineage: fact_donations_analysis_report (t_fact_donations_analysis_
-- report), fact_all_donations (seven t_run_donations_* transformations),
-- t_donations_analysis_tabs (the 13 per-year XLSX sheets).
--
-- Downstream column consumers, confirmed in the .prpt extracts:
--   new_dpr.prpt                          cafe1_donations, box_office_mem_don,
--                                         box_office_mus_exit_don, coatcheck_don
--   finance_mtd_dpr.prpt                  cafe1_donations + the seven legs
--   finance_ytd_dpr.prpt                  cafe1_donations + the seven legs
--   memorial_museum_daily_tracker_ytd     coatcheck_don, cafe1_donations
--   911dw.dayofdata (Retail Performance)  vs_cart_don, mus_exit_don,
--                                         mus_plaza_box_don, retail_cart_don,
--                                         mus_store_don, mem_cart_ask_don,
--                                         cafe1_donations, box_office_mem_don,
--                                         box_office_mus_exit_don
--
-- RATIO RULE (ADR-021). The legacy table stores SIX pre-divided ratios
-- (ms_don_per_store_visitor, ms_don_per_mus_visitor, vesey_don_per_vesey_
-- visitor, cart_don_per_mem_only_visitor, coatcheck_don_per_mus_visitor,
-- mus_exit_don_per_mus_visitor). None of them is reproduced. The numerators and
-- the four denominators are carried; rpt_donations_report_long divides once at
-- display grain. A consumer that needs a legacy ratio column divides two
-- columns of this fact -- it does not read a stored quotient.
--
-- NO CROSS-SOURCE TOTAL IS AUTHORED, deliberately. Legacy publishes two
-- incompatible roll-ups: fact_all_donations' seven leg columns (which count
-- box_office_mus_exit_don twice -- once inside kiosk_coatcheck_donations, once
-- inside mus_exit_donations) and t_reporting_donations' DPR `donations` line
-- (a different cohort again, whose issued leg does not carve out the box-office
-- categories). Choosing between them changes what a certified metric counts, so
-- it is an ADR-005 decision (owner: Chris Wogas) and is NOT made here. Both
-- compositions are reconstructable from the columns below; see NOTES.md.
--
-- SCOPE NOTE (owner: Chris Wogas) — MEMORIAL ATTENDANCE. mem_attendance here is
-- the SENSOURCE memorial line (int_attendance__sensource, reporting facility
-- 2000), which is exactly what legacy t_fact_donations_analysis_report reads
-- (911dw.memorial_attendance, key_facility 2000). It is NOT
-- fct_daily_performance.mem_attendance, which is a typed NULL placeholder
-- because the DPR's memorial line descends from the scan chain and no Gateway
-- ACP resolves to key_facility 2000 (see int_dpr__attendance, 8.7.0). The two
-- memorial definitions are unreconciled across the platform; this fact follows
-- the one its own legacy report used. Same for mus_attendance: the Sensource
-- 1006+3000 passes measure legacy reads here, not the scan-based DPR measure.
--
-- ADR-004: all business logic in dbt. ADR-021: ratios divide at display grain.

{{ config(
    materialized='table',
    cluster_by=['date_key']
) }}

{#- component code -> fact column name. Straight pivot, no arithmetic. -#}
{% set component_columns = [
    ('TICKETING_DON',           'ticketing_donations'),
    ('MEMORIAL_KIOSK_DON',      'memorial_kiosk_don'),
    ('BOX_OFFICE_MEM_DON',      'box_office_mem_don'),
    ('COATCHECK_DON',           'coatcheck_don'),
    ('BOX_OFFICE_MUS_EXIT_DON', 'box_office_mus_exit_don'),
    ('MUS_EXIT_DON',            'mus_exit_don'),
    ('MUS_STORE_DON',           'mus_store_don'),
    ('MEM_CART_ASK_DON',        'mem_cart_ask_don'),
    ('MUS_PLAZA_BOX_DON',       'mus_plaza_box_don'),
    ('MEM_CART_OTHER_DON',      'mem_cart_other_don'),
    ('SHOPIFY_DON',             'shopify_don'),
    ('CAFE_VENDOR_DON',         'cafe_donations'),
    ('CAFE1_DON',               'cafe1_donations'),
    ('VESEY_DON',               'vesey_donations'),
    ('MASK_DON',                'mask_don')
] %}

with sources as (
    select * from {{ ref('int_donations__all_sources') }}
),

sensource as (
    select * from {{ ref('int_attendance__sensource') }}
),

-- Component grain -> day grain. No `else 0`: CAFE_VENDOR_DON is a typed NULL
-- placeholder (cause: NO DATA FEED, 911dw.cafe_performance is not staged) and a
-- zero here would be indistinguishable from a genuine no-donation day.
pivoted as (
    select
        date_key
        {% for code, col in component_columns %}
        , sum(case when donation_component = '{{ code }}' then donation_amount end) as {{ col }}
        {% endfor %}
    from sources
    group by date_key
),

-- Day spine: donations OR visitor counts can exist alone on a date.
date_spine as (
    select date_key from pivoted
    union select date_key from sensource where date_key is not null
),

combined as (
    select
        s.date_key,

        -- ---------------------------------------------------------------
        -- Visitor / attendance denominators (Sensource; see SCOPE NOTE).
        -- Additive counts. Never coalesced to zero: a missing sensor day is
        -- not a zero-visitor day, and these are ratio denominators.
        -- ---------------------------------------------------------------
        v.memorial_attendance                                              as mem_attendance,
        v.museum_attendance                                                as mus_attendance,
        -- t_fact_donations_analysis_report's cart denominator is
        -- (sum(mem_attendance) - sum(mus_attendance)); int_attendance__sensource
        -- authors exactly that difference as memorial_only. Re-projected, not
        -- re-derived, so the Attendance Report and this fact cannot diverge.
        v.memorial_only                                                    as mem_only_visitors,
        v.museum_store                                                     as mus_store_visitors,
        v.museum_store_vesey                                               as vesey_visitors,

        -- ---------------------------------------------------------------
        -- Donation components, one column per authored measure.
        -- ---------------------------------------------------------------
        p.ticketing_donations,
        p.memorial_kiosk_don,
        p.box_office_mem_don,
        p.coatcheck_don,
        p.box_office_mus_exit_don,
        p.mus_exit_don,
        p.mus_store_don,
        p.mem_cart_ask_don,
        p.mus_plaza_box_don,
        p.mem_cart_other_don,
        p.shopify_don,
        p.cafe1_donations,
        p.vesey_donations,
        p.mask_don,
        -- Typed NULL placeholder — cause: NO DATA FEED (911dw.cafe_performance
        -- has no writer in the migrated Pentaho set and no staged equivalent).
        -- The vendor-cafe leg ran 2018-01-01 .. 2023-01-01 only.
        p.cafe_donations,

        -- ---------------------------------------------------------------
        -- Legacy-parity composites. Each is authored ONCE, here, from the
        -- atomic components above — never re-derived from source.
        -- ---------------------------------------------------------------

        -- Memorial (VS) cart donations: the whole %DON-OPS-MEM% Gateway cohort.
        -- t_fact_donations_analysis_report reads it via dim_galaxy_items
        -- account_idno like '%DON-OPS-MEM%'; the platform splits it into the
        -- plaza box-office PLU (authored in int_dpr__donations) plus the rest.
        coalesce(p.memorial_kiosk_don, 0)
          + coalesce(p.box_office_mem_don, 0)                              as vs_cart_don,

        -- Memorial cart retail donations: the whole category-6 cohort at
        -- facility 1020 = donation ask + plaza box + everything else.
        coalesce(p.mem_cart_ask_don, 0)
          + coalesce(p.mus_plaza_box_don, 0)
          + coalesce(p.mem_cart_other_don, 0)                              as retail_cart_don,

        -- fact_all_donations leg 2 (t_run_donations_kiosk_coatcheck): the WHOLE
        -- of fact_all_gateway_donations, i.e. both matrix cohorts including the
        -- two box-office PLUs.
        coalesce(p.memorial_kiosk_don, 0)
          + coalesce(p.box_office_mem_don, 0)
          + coalesce(p.coatcheck_don, 0)
          + coalesce(p.box_office_mus_exit_don, 0)                         as kiosk_coatcheck_donations,

        -- fact_all_donations leg 3 (t_run_donations_exit): legacy UNIONs the
        -- retail exit box with fact_donations_analysis_report.box_office_mus_
        -- exit_don, so the exit-box PLU lands in BOTH this leg and the
        -- kiosk/coatcheck leg above. That overlap is legacy's and is reproduced
        -- verbatim so the two finance reports tie; it is a double count only if
        -- a consumer adds the seven legs together. See NOTES.md, finding 3.
        coalesce(p.mus_exit_don, 0)
          + coalesce(p.box_office_mus_exit_don, 0)                         as mus_exit_leg_donations

    from date_spine s
    left join pivoted   p on s.date_key = p.date_key
    left join sensource v on s.date_key = v.date_key
)

select
    dd.date_key,
    c.date_key                                                             as date_value,
    dd.is_commemoration_day,
    c.* exclude (date_key)
from combined c
inner join {{ ref('dim_date') }} dd
    on c.date_key = dd.date_key
