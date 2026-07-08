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
-- ADR-001 / ADR-004 apply. lin_typ 'S' = sale, 'R' = return.

{{ config(materialized='view') }}

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
            else trim(l.category_code)
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
             then case when l.item_no in ('200933','201229') then 0 else l.ext_price end
             else 0 end                                                     as sale_amount,
        case when l.line_type = 'R' then l.ext_price else 0 end             as return_amount,
        case when l.line_type = 'S' then l.ext_cost else 0 end              as sale_cost

    from lines l
    left join item_master    im  on l.item_no  = im.item_no
    left join item_facility  itf on cast(l.item_no as varchar)  = cast(itf.item_no as varchar)
    left join store_facility stf on cast(l.store_id as varchar) = cast(stf.store_id as varchar)

    -- Legacy t_fact_retail store scope + hygiene filters
    -- Store 1 = Museum Cafe (facility 4007); added 2026-07-08 to fix
    -- cafe1_all_profit / cafe1_donations always reading zero (store was
    -- outside scope and 4007 unmapped). Confirm store id with Gennady.
    where l.store_id in ('1','3','8','9','10','11','12','13','14')
      and coalesce(l.description, '') not ilike '%shipping%'
      and l.item_no <> '201205'
)

select * from mapped