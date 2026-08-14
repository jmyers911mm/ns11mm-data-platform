-- Silver intermediate: CounterPoint (NCR) retail transaction lines
-- ---------------------------------------------------------------------------
-- Domain: retail
-- Grain:  one row per POSTED ps_tkt_hist_lin sale/return line PER FACILITY
--         SCOPE it matches (a line can legitimately produce TWO rows)
--
-- Conforms the CounterPoint POS ticket-history lines into a retail fact with
-- the DPR facility mapping applied. This feeds:
--   mus_store_gross_profit, retail_carts_gross_profit, cafe1_all_profit,
--   audio_tour_headset (MUS AG portion, key_facility 1060),
--   mus_store_donations, mus_exit_donations, cart_donation_ask,
--   ecom_donation_ask.
--
-- Legacy lineage: t_fact_retail (SEVEN store queries), t_fact_cogs,
-- t_fact_num_tickets.
--
-- FACILITY IS A REPORTING VIEW, NOT A PARTITION. Legacy t_fact_retail runs
-- seven independent queries into fact_retail and three stores deliberately
-- land in two facilities each:
--     store 8  -> 1001 Preview/Vesey (Sales 2) AND 1003 Museum Store (Sales 3)
--     store 10 -> 1003 Museum Store  (Sales 3) AND 1030 Atrium (Sales 6)
--     store 1  -> 1001 Preview/Vesey (Sales 2) AND 4007 Museum Cafe (Sales 7)
-- Downstream reports select a specific facility, so the duplication is
-- correct AT FACILITY GRAIN. Any consumer that totals ACROSS facilities must
-- filter `is_primary_facility` or it will double-count stores 1, 8 and 10.
--
-- TICKET-HEADER GATE (8.3.0). Every t_fact_cogs branch joins the ticket header
-- and keeps only `TICKET.TKT_TYP = 'T' AND LINE.LIN_TYP <> 'U'`. This model
-- previously read the line table alone and never joined a header at all, so
-- non-'T' documents (quotes, orders, holds) and 'U' lines were being reported
-- as retail sales and costed. The header join is an INNER join, matching
-- legacy: a line whose header is missing is not a posted retail transaction.
--
-- COST NETTING (8.3.0). t_fact_cogs sums EXT_COST over ALL surviving lines --
-- sale AND return -- while this model previously took cost for line_type 'S'
-- only, so every return gave back revenue but kept its cost and understated
-- gross profit. `net_cost` is the governed cost measure and follows the SAME
-- netting convention as net_amount. `sale_cost` / `return_cost` remain as the
-- additive components; do NOT re-derive netting from them downstream.
--
-- Scope is seed-driven -- one row per legacy query x store in
-- seed_retail_store_scope, carrying the date window, the item carve-in /
-- carve-out, whether the shipping-description filter applies, whether the
-- Sales-4 item->facility override applies, and which price column legacy
-- sums. Edit the seed, not this SQL.
--   Sales 1  stores 2,5,7      -> 1002  (no shipping filter, GROSS_EXT_PRC)
--   Sales 2  stores 1,4,6,8    -> 1001
--   Sales 3  stores 8,9,10     -> 1003, plus (store 14 AND item 201205)
--   Sales 4  stores 11-14      -> item CASE 1040/1060/1070/1080 else 1020,
--                                 excluding item 201205
--   Sales 5  store 3           -> 1234  from 2017-07-01
--   Sales 6  store 10          -> 1030  from 2019-12-10
--   Sales 7  store 1           -> 4007  from 2022-11-28
--
-- Semantic columns (define-once, consumed downstream so DPR marts do not
-- re-hardcode facility numbers or the donation category):
--   facility_group        -- stable name for the resolved key_facility
--   is_donation           -- true for summary_category 6 (legacy DONATE) lines
--   is_primary_facility   -- true on exactly one scope row per line; the row a
--                            cross-facility total may add up
--   legacy_query          -- which t_fact_retail query produced this row
--   net_cost              -- the ONE cost measure; nets returns
--
-- SCOPE NOTE (ADR-005, owner: Gennady Zaritsky): three legacy ambiguities are
-- resolved here in favour of the DATED behaviour. (1) t_fact_retail applies the
-- Sales-4 item CASE with no date bound, while t_fact_cogs gates each carve-out
-- (1040 from 2023-09-04, 1060 from 2024-01-16, 1070/1080 from 2024-01-21) and
-- excludes those items from 1020 entirely; this model uses the cogs cutovers,
-- so pre-cutover MAG / MUS AG / MTG / membership lines report under 1020
-- Memorial Carts. (2) t_fact_retail Sales 7 has no date bound but t_fact_cogs
-- (Cafe1), t_fact_num_tickets and t_reporting_donations all gate store 1 ->
-- 4007 at 2022-11-28; the dated form is implemented. (3) t_fact_retail sums
-- EXT_PRC for Sales 2-7 and GROSS_EXT_PRC for Sales 1, while t_fact_cogs sums
-- GROSS_EXT_PRC in every branch; net_amount follows t_fact_retail (per-scope
-- price_column) because the certified Retail Performance series descends from
-- fact_retail. Confirm all three before the metric is re-certified.
--
-- SCOPE NOTE (owner: Gennady Zaritsky): legacy t_fact_cogs reads the VI_
-- reporting views (VI_PS_TKT_HIST / VI_PS_TKT_HIST_LIN) and joins on
-- DOC_ID *and* BUS_DAT. This model joins the POSTED header
-- stg_counterpoint__pstkthist to the posted lines on doc_id alone -- doc_id is
-- the header primary key at that grain, so the BUS_DAT equality is redundant,
-- and mixing the posted line grain with the VI_ header grain is exactly what
-- the stg_counterpoint__vitkthist header warns against. If the VI_ views ever
-- become the system of record, move BOTH sides at once.
--
-- SCOPE NOTE (owner: Gennady Zaritsky): stg_counterpoint__pstkthist aliases
-- TKT_TYP as `is_return`, which is a misnomer -- the column carries the ticket
-- TYPE ('T' = ticket), not a boolean. ADR-001 keeps staging rename-only, so the
-- alias is read as-is here; correct the staging alias to `ticket_type` in a
-- follow-up and update the one reference below.
--
-- SCOPE NOTE (owner: Gennady Zaritsky): legacy return quantity is
-- SUM(LINE.QTY_SOLD) on 'R' lines, not QTY_RET. This model keeps the platform
-- convention of reading quantity_returned for 'R' lines. If CounterPoint
-- populates QTY_SOLD and QTY_RET differently on returns, net_quantity will
-- diverge from legacy Return_QTY.
--
-- ADR-001 / ADR-004 apply. lin_typ 'S' = sale, 'R' = return, 'U' = excluded.

-- Materialized as a TABLE, not a view: joins (item master + ticket header +
-- four seeds) plus a scope fan-out consumed by 3 downstream models
-- (int_dpr__retail, int_retail__performance, int_retail__customers) each run --
-- a view re-runs the whole thing 3x per build.
-- transient + copy_grants inherited from the intermediate defaults.
{{ config(materialized='table') }}

with lines as (
    select * from {{ ref('stg_counterpoint__pstkthistlin') }}
),

tickets as (
    select * from {{ ref('stg_counterpoint__pstkthist') }}
),

item_master as (
    select * from {{ ref('stg_counterpoint__imitem') }}
),

store_scope as (
    select * from {{ ref('seed_retail_store_scope') }}
),

item_facility as (
    select * from {{ ref('seed_retail_item_facility') }}
),

zero_price_item as (
    select * from {{ ref('seed_retail_zero_price_item') }}
),

donation_item as (
    select * from {{ ref('seed_retail_donation_item') }}
),

facility_area as (
    select * from {{ ref('seed_facility_area') }}
),

-- Posted retail lines only. Legacy t_fact_cogs gates every branch on
-- TICKET.TKT_TYP = 'T' AND LINE.LIN_TYP <> 'U'; the gate belongs here, once,
-- rather than in each consumer.
posted_lines as (
    select
        l.business_date,
        l.doc_id,
        l.line_seq_no,
        l.store_id,
        l.station_id,
        l.item_no,
        l.description,
        l.category_code,
        l.subcategory_code,
        l.line_type,
        l.quantity_sold,
        l.quantity_returned,
        l.ext_price,
        l.gross_ext_price,
        l.ext_cost,
        t.ticket_date
    from lines l
    inner join tickets t
        on l.doc_id = t.doc_id
    -- `is_return` is the staged alias for TKT_TYP (see SCOPE NOTE above).
    where trim(t.is_return) = 'T'
      and trim(l.line_type) <> 'U'
),

-- Fan out each line over every legacy scope row it satisfies. This is the
-- many-to-many store->facility join: stores 1, 8 and 10 match two scope rows.
scoped as (
    select
        cast(l.business_date as date)                       as business_date,
        cast(l.ticket_date as date)                         as ticket_date,
        l.doc_id,
        l.line_seq_no,
        cast(l.store_id as varchar)                         as store_id,
        l.station_id,
        cast(l.item_no as varchar)                          as item_no,
        l.description,
        l.category_code,
        l.subcategory_code,
        l.line_type,
        l.quantity_sold,
        l.quantity_returned,
        l.ext_price,
        l.gross_ext_price,
        l.ext_cost,

        s.legacy_query,
        s.key_facility                                      as scope_key_facility,
        coalesce(s.apply_item_facility_override, false)     as apply_item_facility_override,
        coalesce(s.price_column, 'ext_price')               as price_column,
        coalesce(s.is_primary_facility, true)               as is_primary_facility

    from posted_lines l
    inner join store_scope s
        on cast(l.store_id as varchar) = cast(s.store_id as varchar)
       -- Date window: empty valid_from / valid_to means open-ended.
       and (s.valid_from is null or cast(l.business_date as date) >= s.valid_from)
       and (s.valid_to   is null or cast(l.business_date as date) <= s.valid_to)
       -- Item carve-IN (Sales 3 store 14 / item 201205) and carve-OUT
       -- (Sales 4 excludes 201205). Empty = no item restriction.
       and (nullif(trim(s.item_no_filter), '')  is null
            or cast(l.item_no as varchar) = trim(s.item_no_filter))
       and (nullif(trim(s.item_no_exclude), '') is null
            or cast(l.item_no as varchar) <> trim(s.item_no_exclude))
       -- Legacy DESCR not like '%shipping%' -- present on Sales 2-7, ABSENT on
       -- Sales 1. Applied per scope, not globally.
       and (not coalesce(s.exclude_shipping_descr, true)
            or coalesce(l.description, '') not ilike '%shipping%')
),

-- Resolve the facility. The Sales-4 item->facility override (1040/1060/1070/
-- 1080) applies only inside its own scope, only for the stores the legacy
-- cohort names, and only from the t_fact_cogs cutover date onward.
-- seed_retail_item_facility is unique on (item_no, store_id_scope) so this
-- join cannot fan out.
facility_resolved as (
    select
        sc.*,
        case
            when sc.apply_item_facility_override then coalesce(itf.key_facility, sc.scope_key_facility)
            else sc.scope_key_facility
        end                                                 as key_facility
    from scoped sc
    left join item_facility itf
        on sc.apply_item_facility_override
       and sc.item_no  = cast(itf.item_no as varchar)
       and sc.store_id = cast(itf.store_id_scope as varchar)
       and sc.business_date >= itf.valid_from
),

mapped as (
    select
        fr.business_date,
        fr.ticket_date,
        fr.doc_id,
        fr.line_seq_no,
        fr.store_id,
        fr.station_id,
        fr.item_no,
        coalesce(im.description, fr.description)            as item_description,
        fr.line_type,
        fr.legacy_query,
        fr.key_facility,
        fr.is_primary_facility,

        -- Donation reclass. Legacy folds CATEG_COD='DONATE' to 'Donations'
        -- everywhere; Sales 5 (store 3, ecommerce) ADDITIONALLY reclasses item
        -- 7-00003. The extra reclass is store-scoped in the seed, not global.
        case
            when trim(fr.category_code) = 'DONATE'
              or coalesce(di.reclass_to_donation, false) then 'Donations'
            else coalesce(nullif(trim(fr.category_code), ''), 'UNKNOWN')
        end                                                 as category_code,
        trim(fr.subcategory_code)                           as subcategory_code,

        -- Summary category (legacy key_summary_category: 6 = donations)
        case
            when trim(fr.category_code) = 'DONATE'
              or coalesce(di.reclass_to_donation, false) then 6
            else 1
        end                                                 as summary_category,

        -- Price column follows the legacy query: Sales 1 sums GROSS_EXT_PRC,
        -- Sales 2-7 sum EXT_PRC. Used for BOTH the sale and the return side,
        -- as legacy does.
        case when fr.price_column = 'gross_ext_price'
             then fr.gross_ext_price else fr.ext_price end   as line_price,

        -- Zero-rated SKUs, scoped to the RESOLVED facility so store 1 zero-rates
        -- only '200933' (Sales 7) and store 3 zero-rates nothing (Sales 5).
        -- Zeroing applies to SALE lines only -- return amount is never zeroed.
        (zp.item_no is not null)                            as is_zero_rated,

        fr.quantity_sold,
        fr.quantity_returned,
        fr.ext_cost

    from facility_resolved fr
    left join item_master im
        on fr.item_no = cast(im.item_no as varchar)
    left join donation_item di
        on fr.item_no = cast(di.item_no as varchar)
       and (nullif(trim(di.store_id_scope), '') is null
            or fr.store_id = trim(di.store_id_scope))
    left join zero_price_item zp
        on fr.item_no = cast(zp.item_no as varchar)
       and fr.key_facility = zp.key_facility_scope
),

measured as (
    select
        m.*,

        -- Sale vs return split (additive components)
        case when m.line_type = 'S' then m.quantity_sold else 0 end         as sale_quantity,
        case when m.line_type = 'R' then m.quantity_returned else 0 end     as return_quantity,
        case when m.line_type = 'S'
             then case when m.is_zero_rated then 0 else m.line_price end
             else 0 end                                                     as sale_amount,
        case when m.line_type = 'R' then m.line_price else 0 end            as return_amount,
        case when m.line_type = 'S' then m.ext_cost else 0 end              as sale_cost,
        case when m.line_type = 'R' then m.ext_cost else 0 end              as return_cost,

        -- NET measures — the ONE netting convention (7.9.0). CounterPoint 'R'
        -- lines land with NEGATIVE ext_price / ext_cost / qty, so netting is
        -- ADDITION (matches the legacy-reconciled DPR chain and the legacy
        -- donations rule "nets sale + return"). Downstream models consume
        -- net_amount / net_quantity / net_cost and must NOT re-derive netting
        -- from the components.
        -- CONFIRM against a CounterPoint 'R'-line extract (owner: Gennady);
        -- if returns land positive, flip the sign HERE and nowhere else.
        case when m.line_type = 'S'
             then case when m.is_zero_rated then 0 else m.line_price end
             when m.line_type = 'R' then m.line_price
             else 0 end                                                     as net_amount,
        case when m.line_type = 'S' then m.quantity_sold
             when m.line_type = 'R' then m.quantity_returned
             else 0 end                                                     as net_quantity,
        -- 8.3.0: t_fact_cogs sums EXT_COST over ALL surviving lines, sale AND
        -- return. Same netting convention as net_amount, by construction.
        case when m.line_type in ('S', 'R') then m.ext_cost
             else 0 end                                                     as net_cost

    from mapped m
)

select
    ms.business_date,

    -- Header ticket date (legacy TKT_DT). Retail money is reported on
    -- business_date; transaction COUNTS are reported on ticket_date
    -- (t_fact_num_tickets counts on TKT_DT), so both are carried.
    ms.ticket_date,

    ms.doc_id,
    ms.line_seq_no,
    ms.store_id,
    ms.station_id,
    ms.item_no,
    ms.item_description,
    ms.line_type,

    -- Which legacy t_fact_retail query produced this row. Kept so a facility
    -- number can be traced back to its legacy source without re-reading the
    -- Pentaho export.
    ms.legacy_query,
    ms.key_facility,

    -- TRUE on exactly one scope row per source line. Cross-facility totals
    -- (e.g. fct_daily_operations.retail_revenue) MUST filter on this;
    -- per-facility reporting must NOT.
    ms.is_primary_facility,

    ms.category_code,
    ms.subcategory_code,
    ms.summary_category,

    ms.sale_quantity,
    ms.return_quantity,
    ms.sale_amount,
    ms.return_amount,
    ms.sale_cost,
    ms.return_cost,
    ms.net_amount,
    ms.net_quantity,
    ms.net_cost,

    -- Facility group: single source of truth is seed_facility_area. Downstream
    -- models reference the name, not the literal, so a facility renumber only
    -- touches the seed. Facilities absent from the seed fall back to 'other'
    -- (matches the old CASE else branch).
    coalesce(fa.facility_group, 'other')                                    as facility_group,

    -- Donation flag: derived once here (legacy summary_category 6) so
    -- downstream marts filter on `is_donation` rather than `= 6`.
    (ms.summary_category = 6)                                               as is_donation

from measured ms
left join facility_area fa on ms.key_facility = fa.key_facility
