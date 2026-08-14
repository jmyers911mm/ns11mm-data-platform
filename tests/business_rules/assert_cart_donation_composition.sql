-- Test (business_rule): retail_cart_don equals the whole Memorial Carts donation cohort
-- Severity: warn — this is the one composition in 8.9.0 that rests on an
-- assumption rather than on a proof. retail_cart_don is built as
--   mem_cart_ask_don (item 7-999) + mus_plaza_box_don (item 101165) + mem_cart_other_don
-- and mus_plaza_box_don is authored in int_dpr__retail with NO facility filter
-- (legacy t_reporting_mus_donation_box is item-scoped and facility-agnostic),
-- while the other two terms are scoped to facility_group 'memorial_carts'. If
-- item 101165 ever rings up outside Memorial Carts, retail_cart_don overstates
-- the legacy cohort by exactly those dollars.
--
-- This test reads the whole category-6 cohort at Memorial Carts directly from
-- int_counterpoint__retail_lines (legacy t_run_donations_retail_cart:
-- key_facility 1020, key_summary_category 6) and compares. It is WARN, not
-- error, because a non-zero result is a real business finding — the plaza box
-- has moved — not necessarily a code defect. Promote to error once the
-- verification query in NOTES.md §5 has returned zero rows on live data and
-- the facility scoping of donation_box has been settled with Gennady Zaritsky.
--
-- Note the is_primary_facility filter is deliberately ABSENT: this is a
-- per-facility cohort, and int_counterpoint__retail_lines' contract is that
-- only cross-facility totals filter that flag.

{{ config(severity='warn') }}

with source_cohort as (
    select
        cast(business_date as date)                                         as date_key,
        sum(case when facility_group = 'memorial_carts' and is_donation
                 then net_amount else 0 end)                                as cart_cohort
    from {{ ref('int_counterpoint__retail_lines') }}
    group by 1
),

fact as (
    select
        date_key,
        retail_cart_don,
        mem_cart_ask_don,
        mus_plaza_box_don,
        mem_cart_other_don
    from {{ ref('fct_donations') }}
)

select
    coalesce(f.date_key, s.date_key)                                        as date_key,
    coalesce(s.cart_cohort, 0)                                              as source_cart_cohort,
    coalesce(f.retail_cart_don, 0)                                          as fact_retail_cart_don,
    coalesce(f.retail_cart_don, 0) - coalesce(s.cart_cohort, 0)             as excess_from_plaza_box,
    f.mem_cart_ask_don,
    f.mus_plaza_box_don,
    f.mem_cart_other_don
from fact f
full outer join source_cohort s on f.date_key = s.date_key
where abs(coalesce(f.retail_cart_don, 0) - coalesce(s.cart_cohort, 0)) > 0.01
