-- Silver intermediate: CounterPoint (NCR) retail transaction lines
-- ---------------------------------------------------------------------------
-- Domain: retail
-- Grain:  one row per ps_tkt_hist_lin sale/return line
--
-- Conforms the CounterPoint POS ticket-history lines into a retail fact with
-- the DPR facility mapping applied. This feeds:
--   mus_store_gross_profit, retail_carts_gross_profit, cafe1_all_profit,
--   audio_tour_headset (MUS AG portion, key_facility 1060),
--   mus_store_donations, mus_exit_donations, cart_donation_ask,
--   ecom_donation_ask.
--
-- Legacy lineage: t_fact_retail, t_fact_cogs, t_fact_num_tickets.
-- The item->facility mapping in legacy t_fact_retail:
--     201114 -> 1040 (MAG),  201197 -> 1060 (MUS AG),
--     101504 -> 1070,        100564-100569 -> 1080,
--     else store 11-14 -> 1020 (Memorial Carts).
-- Store-id families (from j_run_retail notes):
--     8,9,10 -> 1003 Museum Store;   3 -> 1234 Ecommerce.
--
-- Semantic columns (define-once, consumed downstream so DPR marts do not
-- re-hardcode facility numbers or the donation category):
--   facility_group -- stable name for the resolved key_facility
--   is_donation    -- true for summary_category 6 (legacy DONATE) lines
-- Downstream models (e.g. int_dpr__retail) filter on these instead of
-- repeating literals like `key_facility = 1003` and `summary_category = 6`.
--
-- Config-as-data (2026-07-23 cleanup):
--   * facility_group name comes from seed_facility_area (was an inline CASE).
--   * store scope, zero-price SKUs, and dropped items are seed-driven
--     (seed_retail_store_scope / seed_retail_zero_price_item /
--      seed_retail_excluded_item) -- edit the seed, not this SQL.
--
-- ADR-001 / ADR-004 apply. lin_typ 'S' = sale, 'R' = return.

-- Materialized as a TABLE, not a view: joins (item master + seeds) consumed by
-- 3 downstream models (int_dpr__retail, int_retail__performance,
-- int_retail__customers) each run — a view re-runs the joins 3x per build.
-- transient + copy_grants inherited from the intermediate defaults.
{{ config(materialized='table') }}

with lines as (
    select * from {{ ref('stg_counterpoint__pstkthistlin') }}
),

item_master as (
    select
        item_no,
        description       as item_description,
        category_code,
        subcategory_code
    from {{ ref('stg_counterpoint__imitem') }}
),

item_facility as (
    select item_no, key_facility
    from {{ ref('seed_retail_item_facility') }}
),

store_facility as (
    select store_id, key_facility
    from {{ ref('seed_retail_store_facility') }}
),

-- key_facility -> stable facility_group name (was an inline CASE)
facility_area as (
    select key_facility, facility_group
    from {{ ref('seed_facility_area') }}
),

-- Zero-rated SKUs: sale price contributes 0 (legacy t_fact_retail)
zero_price_item as (
    select item_no
    from {{ ref('seed_retail_zero_price_item') }}
),

mapped as (
    select
        l.business_date,
        l.doc_id,
        l.line_seq_no,
        l.store_id,
        l.station_id,
        l.item_no,
        coalesce(im.item_description, l.description)         as item_description,
        l.line_type,

        -- Facility key mapping (legacy t_fact_retail CASE), now seed-driven:
        -- item-number override wins; otherwise fall back to store mapping;
        -- default to Memorial Carts (1020) when neither matches.
        coalesce(itf.key_facility, stf.key_facility, 1020)                  as key_facility,

        -- Category normalization (legacy folds DONATE -> Donations)
        case
            when trim(l.category_code) = 'DONATE' then 'Donations'
            else coalesce(nullif(trim(l.category_code), ''), 'UNKNOWN')
        end                                                                 as category_code,
        trim(l.subcategory_code)                                            as subcategory_code,

        -- Summary category (legacy key_summary_category: 6 = donations)
        case
            when trim(l.category_code) = 'DONATE' then 6
            else 1
        end                                                                 as summary_category,

        -- Sale vs return split (additive measures)
        case when l.line_type = 'S' then l.quantity_sold else 0 end         as sale_quantity,
        case when l.line_type = 'R' then l.quantity_returned else 0 end     as return_quantity,
        case when l.line_type = 'S'
             then case when zp.item_no is not null then 0 else l.ext_price end
             else 0 end                                                     as sale_amount,
        case when l.line_type = 'R' then l.ext_price else 0 end             as return_amount,
        case when l.line_type = 'S' then l.ext_cost else 0 end              as sale_cost,

        -- NET measures — the ONE netting convention (7.9.0). CounterPoint 'R'
        -- lines land with NEGATIVE ext_price / qty, so netting is ADDITION
        -- (matches the legacy-reconciled DPR chain and the legacy donations
        -- rule "nets sale + return"). Downstream models consume net_amount /
        -- net_quantity and must NOT re-derive netting from the components.
        -- CONFIRM against a CounterPoint 'R'-line extract (owner: Gennady);
        -- if returns land positive, flip the sign HERE and nowhere else.
        case when l.line_type = 'S'
             then case when zp.item_no is not null then 0 else l.ext_price end
             when l.line_type = 'R' then l.ext_price
             else 0 end                                                     as net_amount,
        case when l.line_type = 'S' then l.quantity_sold
             when l.line_type = 'R' then l.quantity_returned
             else 0 end                                                     as net_quantity

    from lines l
    left join item_master     im  on l.item_no  = im.item_no
    left join item_facility   itf on cast(l.item_no as varchar)  = cast(itf.item_no as varchar)
    left join store_facility  stf on cast(l.store_id as varchar) = cast(stf.store_id as varchar)
    left join zero_price_item zp  on cast(l.item_no as varchar)  = cast(zp.item_no as varchar)

    -- Legacy t_fact_retail store scope + hygiene filters (scope/exclusions seed-driven).
    -- Store 1 = Museum Cafe (facility 4007); added 2026-07-08 to fix
    -- cafe1_all_profit / cafe1_donations always reading zero.
    where l.store_id in (select store_id from {{ ref('seed_retail_store_scope') }})
      and coalesce(l.description, '') not ilike '%shipping%'
      and l.item_no not in (select item_no from {{ ref('seed_retail_excluded_item') }})
)

select
    m.*,

    -- Facility group: single source of truth is seed_facility_area. Downstream
    -- models reference the name, not the literal, so a facility renumber only
    -- touches the seed. Facilities absent from the seed fall back to 'other'
    -- (matches the old CASE else branch).
    coalesce(fa.facility_group, 'other')                                    as facility_group,

    -- Donation flag: derived once here (legacy summary_category 6) so
    -- downstream marts filter on `is_donation` rather than `= 6`.
    (m.summary_category = 6)                                                as is_donation

from mapped m
left join facility_area fa on m.key_facility = fa.key_facility
