-- Test (reconciliation): fct_donations and fct_daily_performance agree on every shared donation line
-- Severity: error — the two facts are the two published homes of the same
-- eleven donation measures. fct_daily_performance carries them for the DPR;
-- fct_donations carries them for the Donations Analysis Report and for the five
-- .prpt reports that read the legacy fact_donations_analysis_report directly.
-- Both project the SAME upstream authored columns (int_dpr__donations,
-- int_dpr__retail) — neither re-derives them — so any difference means a
-- projection was edited on one side only, and two live reports would then
-- publish different numbers for the same donation. That is precisely the
-- failure mode ADR-021's "composites authored once" rule exists to prevent, so
-- this fails the build rather than warning.
--
-- The eleven pairs are name-mapped because fct_donations deliberately uses the
-- LEGACY column names (five migrated reports bind to them) while
-- fct_daily_performance uses the platform DPR names.

with dpr as (
    select
        date_key,
        ticketing_donations,
        box_office_mem_don,
        box_office_mus_exit_don,
        coatcheck_don,
        mus_store_donations,
        mus_exit_donations,
        cart_donation_ask,
        donation_box,
        ecom_donation_ask,
        cafe1_donations,
        mask_donations
    from {{ ref('fct_daily_performance') }}
),

don as (
    select
        date_key,
        ticketing_donations,
        box_office_mem_don,
        box_office_mus_exit_don,
        coatcheck_don,
        mus_store_don,
        mus_exit_don,
        mem_cart_ask_don,
        mus_plaza_box_don,
        shopify_don,
        cafe1_donations,
        mask_don
    from {{ ref('fct_donations') }}
),

compared as (
    select
        coalesce(p.date_key, d.date_key)                                    as date_key,

        coalesce(p.ticketing_donations, 0)      - coalesce(d.ticketing_donations, 0)     as diff_ticketing_donations,
        coalesce(p.box_office_mem_don, 0)       - coalesce(d.box_office_mem_don, 0)      as diff_box_office_mem_don,
        coalesce(p.box_office_mus_exit_don, 0)  - coalesce(d.box_office_mus_exit_don, 0) as diff_box_office_mus_exit_don,
        coalesce(p.coatcheck_don, 0)            - coalesce(d.coatcheck_don, 0)           as diff_coatcheck_don,
        coalesce(p.mus_store_donations, 0)      - coalesce(d.mus_store_don, 0)           as diff_mus_store_don,
        coalesce(p.mus_exit_donations, 0)       - coalesce(d.mus_exit_don, 0)            as diff_mus_exit_don,
        coalesce(p.cart_donation_ask, 0)        - coalesce(d.mem_cart_ask_don, 0)        as diff_mem_cart_ask_don,
        coalesce(p.donation_box, 0)             - coalesce(d.mus_plaza_box_don, 0)       as diff_mus_plaza_box_don,
        coalesce(p.ecom_donation_ask, 0)        - coalesce(d.shopify_don, 0)             as diff_shopify_don,
        coalesce(p.cafe1_donations, 0)          - coalesce(d.cafe1_donations, 0)         as diff_cafe1_donations,
        coalesce(p.mask_donations, 0)           - coalesce(d.mask_don, 0)                as diff_mask_don

    from dpr p
    full outer join don d on p.date_key = d.date_key
)

select *
from compared
where abs(diff_ticketing_donations)     > 0.01
   or abs(diff_box_office_mem_don)      > 0.01
   or abs(diff_box_office_mus_exit_don) > 0.01
   or abs(diff_coatcheck_don)           > 0.01
   or abs(diff_mus_store_don)           > 0.01
   or abs(diff_mus_exit_don)            > 0.01
   or abs(diff_mem_cart_ask_don)        > 0.01
   or abs(diff_mus_plaza_box_don)       > 0.01
   or abs(diff_shopify_don)             > 0.01
   or abs(diff_cafe1_donations)         > 0.01
   or abs(diff_mask_don)                > 0.01
