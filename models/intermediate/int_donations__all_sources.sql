-- Silver intermediate: every donation source on one grain (fact_all_donations equivalent)
-- ---------------------------------------------------------------------------
-- Domain: donations
-- Grain:  one row per date_key x donation_component
--
-- The platform equivalent of legacy 911dw.fact_all_donations. Legacy writes
-- that table from SEVEN independent transformations, each InsertUpdating its
-- own column on a key_date row; this model carries the same information one
-- level finer -- at COMPONENT grain -- so the composites the legacy legs are
-- made of stay separable, and tags each component with the fact_all_donations
-- column it rolls into (legacy_leg). Feeds fct_donations, which pivots to the
-- legacy column shape the five downstream reports bind to.
--
-- Legacy lineage: fact_all_donations, written by t_run_donations_ticketing,
-- t_run_donations_kiosk_coatcheck, t_run_donations_exit,
-- t_run_donations_mus_store, t_run_donations_retail_cart,
-- t_run_donations_shopify, t_run_donations_cafe. Read live by
-- finance_mtd_dpr.prpt and finance_ytd_dpr.prpt (seven leg columns each).
-- Also: t_fact_all_gateway_donations_new (the Gateway kiosk/coatcheck journal
-- cohort) and t_reporting_donations (the DPR donations roll-up).
--
-- WHAT IS RE-PROJECTED AND WHAT IS NEW (ADR-021: a donation total authored
-- twice is a defect, so nothing already authored upstream is re-derived here):
--
--   RE-PROJECTED from int_dpr__donations (Gateway item journal):
--     TICKETING_DON            <- ticketing_donations (issued + unissued, 8.8.0)
--     BOX_OFFICE_MEM_DON       <- box_office_mem_don      (PLU DONOPSMEM003)
--     BOX_OFFICE_MUS_EXIT_DON  <- box_office_mus_exit_don (PLU DONOPSMUS003)
--     COATCHECK_DON            <- coatcheck_don (%DON-OPS-MUS% less the exit PLU)
--
--   RE-PROJECTED from int_dpr__retail (CounterPoint retail lines):
--     MUS_STORE_DON            <- mus_store_donations
--     MUS_EXIT_DON             <- mus_exit_donations   (item 101375 / legacy 886)
--     MEM_CART_ASK_DON         <- cart_donation_ask    (item 7-999 / legacy 483)
--     MUS_PLAZA_BOX_DON        <- donation_box         (item 101165 / legacy 3375)
--     SHOPIFY_DON              <- ecom_donation_ask    (facility 1234)
--     CAFE1_DON                <- cafe1_donations      (facility 4007)
--     MASK_DON                 <- mask_donations       (item 200704, dormant)
--
--   NEW in 8.9.0 (no existing platform home; authored here, once):
--     MEMORIAL_KIOSK_DON  -- the %DON-OPS-MEM% Gateway cohort MINUS the
--        box-office plaza PLU that int_dpr__donations already authors. Legacy
--        reads the whole cohort as vs_cart_donations; carrying only the
--        complement keeps the plaza box authored exactly once, and
--        fct_donations recomposes vs_cart_don = this + box_office_mem_don.
--     MEM_CART_OTHER_DON  -- Memorial Carts donation lines that are neither the
--        donation ask nor the plaza box. Same complement logic: legacy's
--        retail_cart_donations is the whole category-6 cohort at facility 1020,
--        and fct_donations recomposes it from ask + plaza box + this.
--     VESEY_DON  -- Preview Site / Vesey Street donation lines. Report-only:
--        no legacy leg, no DPR line, nothing in the platform reads it today.
--
--   STUB (typed NULL, ADR-021 cause: NO DATA FEED):
--     CAFE_VENDOR_DON -- legacy t_run_donations_cafe reads 911dw.cafe_performance
--        (2018-01-01 .. 2023-01-01). That table has no writer in the migrated
--        Pentaho set and no staged equivalent. NOT zero-filled; the layout seed
--        marks CAFE_DONATIONS and LEG_CAFE 'Stub'. The vendor-cafe era ended
--        2023-01-01, so the placeholder is historical, not ongoing.
--
-- SCOPE NOTE (ADR-005 not required; recorded for the owner, Gennady Zaritsky):
-- the legacy legs filter on 911dw.dim_item_descr surrogate keys
-- (482, 485, 2168-2173, 3373, 3753, 5156, 5179, 583, 598, 931) inside an
-- already-donation category. dim_item_descr is not staged and the surrogate ->
-- item_no crosswalk cannot be reconstructed, so the whitelists are approximated
-- by the category filter (is_donation, legacy key_summary_category = 6) at the
-- same facility. That makes MUS_STORE_DON, MEM_CART_OTHER_DON and VESEY_DON
-- supersets of the legacy cohorts where a non-whitelisted donation SKU exists.
-- The four SKUs legacy actually names in DPR transformations are resolved and
-- seeded (seed_retail_donation_item); the rest are marked 'Partial' in the
-- layout seed. Do not zero-fill and do not guess the missing SKUs.
--
-- ADR-021 ratio rule: additive dollars only. Every per-visitor ratio built on
-- these divides at display grain in rpt_donations_report_long.
-- ADR-004: all business logic in dbt.

{{ config(materialized='view') }}

{#- component -> (legacy fact_all_donations column | none), source system,   -#}
{#- and the expression, which reads the `wide` CTE (alias w) below. Order    -#}
{#- drives nothing; the report layout seed owns display order.               -#}
{% set components = [
    ('TICKETING_DON',           'ticketing_donations',        'gateway',      'coalesce(w.ticketing_donations, 0)'),
    ('MEMORIAL_KIOSK_DON',      'kiosk_coatcheck_donations',  'gateway',      'coalesce(w.memorial_kiosk_don, 0)'),
    ('BOX_OFFICE_MEM_DON',      'kiosk_coatcheck_donations',  'gateway',      'coalesce(w.box_office_mem_don, 0)'),
    ('COATCHECK_DON',           'kiosk_coatcheck_donations',  'gateway',      'coalesce(w.coatcheck_don, 0)'),
    ('BOX_OFFICE_MUS_EXIT_DON', 'kiosk_coatcheck_donations',  'gateway',      'coalesce(w.box_office_mus_exit_don, 0)'),
    ('MUS_EXIT_DON',            'mus_exit_donations',         'counterpoint', 'coalesce(w.mus_exit_donations, 0)'),
    ('MUS_STORE_DON',           'mus_store_donations',        'counterpoint', 'coalesce(w.mus_store_donations, 0)'),
    ('MEM_CART_ASK_DON',        'retail_cart_donations',      'counterpoint', 'coalesce(w.cart_donation_ask, 0)'),
    ('MUS_PLAZA_BOX_DON',       'retail_cart_donations',      'counterpoint', 'coalesce(w.donation_box, 0)'),
    ('MEM_CART_OTHER_DON',      'retail_cart_donations',      'counterpoint', 'coalesce(w.mem_cart_other_don, 0)'),
    ('SHOPIFY_DON',             'shopify_donations',          'counterpoint', 'coalesce(w.ecom_donation_ask, 0)'),
    ('CAFE_VENDOR_DON',         'cafe_donations',             'vendor_cafe',  'cast(null as number(38,4))'),
    ('CAFE1_DON',               none,                         'counterpoint', 'coalesce(w.cafe1_donations, 0)'),
    ('VESEY_DON',               none,                         'counterpoint', 'coalesce(w.vesey_don, 0)'),
    ('MASK_DON',                none,                         'counterpoint', 'coalesce(w.mask_donations, 0)')
] %}

with gateway_lines as (
    select * from {{ ref('int_gateway__item_journal_lines') }}
),

gateway_donations as (
    select * from {{ ref('int_dpr__donations') }}
),

retail_lines as (
    select * from {{ ref('int_counterpoint__retail_lines') }}
),

retail_donations as (
    select * from {{ ref('int_dpr__retail') }}
),

donation_item as (
    select item_no, donation_line
    from {{ ref('seed_retail_donation_item') }}
),

-- NEW LEG. The %DON-OPS-MEM% memorial-kiosk cohort less the plaza box-office
-- PLU that int_dpr__donations already authors as box_office_mem_don. The
-- quantity <> 0 guard is legacy's: t_fact_all_gateway_donations_new ends its
-- kiosk/coatcheck cohort with `and JNLDetails.Qty <> 0` (zero-quantity detail
-- lines are adjustments, voids and re-postings that carry an amount but no
-- donation event). Same guard int_dpr__donations applies to its three cohorts.
memorial_kiosk as (
    select
        date_key,
        sum(case when matrix_code like '%DON-OPS-MEM%'
                  and plu <> 'DONOPSMEM003'
                  and coalesce(quantity, 0) <> 0
                 then amount else 0 end)                                    as memorial_kiosk_don
    from gateway_lines
    group by date_key
),

-- NEW LEGS. Two CounterPoint donation cohorts with no existing platform home.
-- Facility selection is by facility_group (seed_facility_area), never by raw
-- key_facility, and the donation flag is int_counterpoint__retail_lines'
-- is_donation (legacy key_summary_category = 6) -- neither is re-derived here.
-- is_primary_facility is deliberately NOT filtered: both cohorts are read at
-- FACILITY grain, which is the grain the legacy queries use, and filtering it
-- would drop store 8's Vesey rows and store 1's Vesey rows.
counterpoint_new as (
    select
        cast(r.business_date as date)                                       as date_key,

        -- Preview Site / Vesey Street donations. Legacy t_fact_donations_
        -- analysis_report: fact_retail at key_facility 1001, key_summary_
        -- category 6, key_item_descr NOT IN (583,598,886,931,2168..2173).
        -- Only 886 (-> item 101375, donation_line 'mus_exit') is resolvable;
        -- the other exclusions cannot be reconstructed (see SCOPE NOTE).
        sum(case when r.facility_group = 'preview_vesey'
                  and r.is_donation
                  and coalesce(di.donation_line, '') <> 'mus_exit'
                 then r.net_amount else 0 end)                              as vesey_don,

        -- Memorial Carts donations that are NEITHER the donation ask NOR the
        -- plaza box -- the complement of the two lines int_dpr__retail already
        -- authors, so retail_cart_don recomposes without authoring the total
        -- twice. Legacy t_run_donations_retail_cart is the whole category-6
        -- cohort at key_facility 1020 from 2016-01-01.
        sum(case when r.facility_group = 'memorial_carts'
                  and r.is_donation
                  and coalesce(di.donation_line, '') not in ('cart_ask', 'plaza_box')
                 then r.net_amount else 0 end)                              as mem_cart_other_don

    from retail_lines r
    left join donation_item di
        on cast(r.item_no as varchar) = cast(di.item_no as varchar)
    group by 1
),

-- Day spine across every contributing source, so a date present in one source
-- and absent from another still produces a full component set.
date_spine as (
    select cast(date_key as date) as date_key from gateway_donations where date_key is not null
    union select cast(date_key as date) from memorial_kiosk    where date_key is not null
    union select cast(date_key as date) from retail_donations  where date_key is not null
    union select cast(date_key as date) from counterpoint_new  where date_key is not null
),

wide as (
    select
        s.date_key,
        g.ticketing_donations,
        g.box_office_mem_don,
        g.box_office_mus_exit_don,
        g.coatcheck_don,
        mk.memorial_kiosk_don,
        c.mus_store_donations,
        c.mus_exit_donations,
        c.cart_donation_ask,
        c.donation_box,
        c.ecom_donation_ask,
        c.cafe1_donations,
        c.mask_donations,
        n.vesey_don,
        n.mem_cart_other_don
    from date_spine s
    left join gateway_donations g  on s.date_key = cast(g.date_key as date)
    left join memorial_kiosk    mk on s.date_key = cast(mk.date_key as date)
    left join retail_donations  c  on s.date_key = cast(c.date_key as date)
    left join counterpoint_new  n  on s.date_key = n.date_key
),

unpivoted as (
    {% for code, leg, system, expr in components %}
    select
        w.date_key,
        '{{ code }}'                                                        as donation_component,
        {% if leg %}'{{ leg }}'{% else %}cast(null as varchar){% endif %}    as legacy_leg,
        '{{ system }}'                                                      as source_system,
        cast({{ expr }} as number(38,4))                                     as donation_amount
    from wide w
    {% if not loop.last %}union all{% endif %}
    {% endfor %}
)

select
    date_key,
    donation_component,
    legacy_leg,
    source_system,
    donation_amount
from unpivoted
