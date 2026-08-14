-- Silver intermediate: retail customer / transaction counts
-- ---------------------------------------------------------------------------
-- Domain: retail
-- Grain: one row per ticket_date (date_key) x key_facility
--
-- Replaces legacy 911dw.fact_num_tickets (t_fact_num_tickets from PS_TKT_HIST +
-- PS_TKT_HIST_LIN). Counts distinct retail transactions per selling area.
--
-- 8.3.0 REWRITE. The previous version counted `distinct doc_id` off
-- int_counterpoint__retail_lines grouped by business_date and key_facility.
-- That was wrong on three counts:
--   1. Legacy counts on the HEADER ticket date (TICKET.TKT_DT), not the line
--      business date (LINE.BUS_DAT). A ticket opened before midnight and posted
--      to the next business day lands on a different day in each convention.
--   2. Legacy defines each facility's cohort with an INDEPENDENT store list,
--      start date and doc_id semi-join -- eleven queries, not one grouped scan.
--      Memorial Carts (1020) is stores 11,12,13 -- NOT 14 -- and EXCLUDES any
--      doc that contains a carve-out SKU; MAG / MUS AG / MTG / Membership use
--      the INVERSE semi-join (docs that DO contain the SKU). A doc containing
--      both a cart item and a MAG item counts once at 1040 and not at all at
--      1020; the old grouped count put it in both.
--   3. Visitors Center (1002) is a STATION cohort, not a store cohort.
--
-- Counts are a COUNT(DISTINCT) and therefore NOT additive across category,
-- which is why they live here at the facility grain rather than in
-- int_retail__performance (category grain). The Retail Performance Report's
-- customers_mus_store / customers_mem_cart / cafe1_transactions all resolve to
-- this measure per facility.
--
-- Legacy lineage: t_fact_num_tickets (eleven TableInput steps). Reads staging
-- directly rather than int_counterpoint__retail_lines because the cohorts,
-- start dates and semi-joins are the sales scope's, and the semi-joins must see
-- ALL lines on a doc, not only the in-scope ones.
--
-- SCOPE NOTE (owner: Gennady Zaritsky): the legacy Museum Store step reads
--     WHERE STR_ID IN ('8','9','10') OR (STR_ID='14' AND doc_id IN (...))
--       AND TKT_DT > '20170423'
-- SQL binds AND tighter than OR, so the 2017-04-23 start date applies ONLY to
-- the store-14 carve-in and stores 8/9/10 are unbounded. That is almost
-- certainly a legacy bug, but it is the behaviour that produced the certified
-- series, so it is reproduced verbatim. Confirm before "fixing" it (ADR-005).
--
-- SCOPE NOTE (owner: Gennady Zaritsky): Visitors Center (1002) is defined by a
-- STATION list in t_fact_num_tickets but by stores 2/5/7 in t_fact_retail, so
-- the count and the sales for 1002 are not drawn from the same population. The
-- station list is reproduced here because it is what fact_num_tickets used.
--
-- SCOPE NOTE (owner: Gennady Zaritsky): the Membership (1080) cohort starts
-- 2023-11-29 in t_fact_num_tickets but 2024-01-21 in t_fact_cogs. Each legacy
-- start date is kept in its own model, so 1080 has counts for ~7 weeks before
-- it has sales. Pick one date before publishing a 1080 per-transaction ratio.
--
-- SCOPE NOTE (owner: Gennady Zaritsky): legacy counts COUNT(TICKET.TKT_NO),
-- not COUNT(DISTINCT ...). PS_TKT_HIST is one row per doc_id, so
-- count(distinct doc_id) is equivalent and is used here because it survives a
-- future header-grain change.
--
-- ADR-001: staging is upstream and carries no business logic; the cohort rules
-- live here. ADR-004: all business logic in dbt, not Power BI.

{{ config(materialized='view') }}

with tickets as (
    select * from {{ ref('stg_counterpoint__pstkthist') }}
),

lines as (
    select * from {{ ref('stg_counterpoint__pstkthistlin') }}
),

ticket_header as (
    select
        doc_id,
        cast(store_id as varchar)       as store_id,
        trim(station_id)                as station_id,
        cast(ticket_date as date)       as ticket_day
    from tickets
),

ticket_line as (
    select
        doc_id,
        cast(store_id as varchar)       as store_id,
        cast(item_no as varchar)        as item_no,
        cast(business_date as date)     as business_date,
        description
    from lines
),

-- ── doc_id cohorts (legacy semi-joins) ────────────────────────────────────
-- Memorial Carts EXCLUDES any doc touching a carve-out SKU; the four carve-out
-- facilities INCLUDE exactly those docs. Same subquery shape, opposite sense.

carts_carveout_docs as (
    -- Consumed with NOT IN, so a null doc_id would wipe the whole 1020 cohort;
    -- excluded explicitly rather than relying on the source never having one.
    select distinct doc_id
    from ticket_line
    where store_id in ('11', '12', '13')
      and coalesce(description, '') not ilike '%shipping%'
      and business_date >= cast('2023-09-04' as date)
      and item_no in ('200933', '201229', '201114', '201197')
      and doc_id is not null
),

mag_docs as (
    select distinct doc_id
    from ticket_line
    where store_id in ('11', '12', '13', '14')
      and coalesce(description, '') not ilike '%shipping%'
      and business_date >= cast('2023-09-04' as date)
      and item_no = '201114'
),

musag_docs as (
    select distinct doc_id
    from ticket_line
    where store_id in ('11', '12', '13', '14')
      and coalesce(description, '') not ilike '%shipping%'
      and business_date >= cast('2024-01-16' as date)
      and item_no = '201197'
),

mtg_docs as (
    select distinct doc_id
    from ticket_line
    where store_id = '14'
      and coalesce(description, '') not ilike '%shipping%'
      and business_date >= cast('2024-01-21' as date)
      and item_no = '101504'
),

membership_docs as (
    select distinct doc_id
    from ticket_line
    where store_id = '14'
      and coalesce(description, '') not ilike '%shipping%'
      and business_date >= cast('2023-11-29' as date)
      and item_no in ('100564', '100565', '100566', '100567', '100568', '100569')
),

-- Museum Store carve-IN: store-14 docs containing item 201205. Legacy applies
-- NO shipping filter to this subquery.
mus_store_str14_docs as (
    select distinct doc_id
    from ticket_line
    where store_id = '14'
      and business_date > cast('2024-01-01' as date)
      and item_no = '201205'
),

-- ── facility cohorts (one branch per legacy TableInput step) ──────────────

visitors_center as (
    -- 1002. Station cohort, not a store cohort (see SCOPE NOTE).
    select
        t.ticket_day                                as date_key,
        1002                                        as key_facility,
        count(distinct t.doc_id)                    as transactions
    from ticket_header t
    where t.station_id in (
              '21', '24', '25', '27', '28',
              'VC-1', 'VC-2', 'VC-3', 'VC-4', 'VC-5', 'VC-6',
              'VC MGR 1', 'VC MGR 2',
              'MOBILE10', 'MOBILE11', 'MOBILE12'
          )
      and t.ticket_day > cast('2012-10-28' as date)   -- legacy: strictly greater
    group by 1
),

preview_vesey as (
    -- 1001
    select
        t.ticket_day                                as date_key,
        1001                                        as key_facility,
        count(distinct t.doc_id)                    as transactions
    from ticket_header t
    where t.store_id in ('1', '4', '6', '8')
      and t.ticket_day >= cast('2014-07-09' as date)
    group by 1
),

museum_store as (
    -- 1003. Precedence reproduced verbatim: the start date binds only to the
    -- store-14 carve-in (see SCOPE NOTE).
    select
        t.ticket_day                                as date_key,
        1003                                        as key_facility,
        count(distinct t.doc_id)                    as transactions
    from ticket_header t
    where t.store_id in ('8', '9', '10')
       or (
              t.store_id = '14'
          and t.doc_id in (select doc_id from mus_store_str14_docs)
          and t.ticket_day > cast('2017-04-23' as date)
          )
    group by 1
),

memorial_carts as (
    -- 1020. Stores 11,12,13 only -- NOT 14 -- minus the carve-out docs.
    select
        t.ticket_day                                as date_key,
        1020                                        as key_facility,
        count(distinct t.doc_id)                    as transactions
    from ticket_header t
    where t.store_id in ('11', '12', '13')
      and t.ticket_day >= cast('2015-05-25' as date)
      and t.doc_id not in (select doc_id from carts_carveout_docs)
    group by 1
),

atrium as (
    -- 1030
    select
        t.ticket_day                                as date_key,
        1030                                        as key_facility,
        count(distinct t.doc_id)                    as transactions
    from ticket_header t
    where t.store_id = '10'
      and t.ticket_day >= cast('2019-12-10' as date)
    group by 1
),

ecommerce as (
    -- 1234
    select
        t.ticket_day                                as date_key,
        1234                                        as key_facility,
        count(distinct t.doc_id)                    as transactions
    from ticket_header t
    where t.store_id = '3'
      and t.ticket_day >= cast('2017-07-01' as date)
    group by 1
),

museum_cafe as (
    -- 4007
    select
        t.ticket_day                                as date_key,
        4007                                        as key_facility,
        count(distinct t.doc_id)                    as transactions
    from ticket_header t
    where t.store_id = '1'
      and t.ticket_day >= cast('2022-11-28' as date)
    group by 1
),

mag_cart as (
    -- 1040
    select
        t.ticket_day                                as date_key,
        1040                                        as key_facility,
        count(distinct t.doc_id)                    as transactions
    from ticket_header t
    where t.store_id in ('11', '12', '13', '14')
      and t.ticket_day >= cast('2023-09-04' as date)
      and t.doc_id in (select doc_id from mag_docs)
    group by 1
),

mus_audio_guide as (
    -- 1060
    select
        t.ticket_day                                as date_key,
        1060                                        as key_facility,
        count(distinct t.doc_id)                    as transactions
    from ticket_header t
    where t.store_id in ('11', '12', '13', '14')
      and t.ticket_day >= cast('2024-01-16' as date)
      and t.doc_id in (select doc_id from musag_docs)
    group by 1
),

museum_tour_guides as (
    -- 1070
    select
        t.ticket_day                                as date_key,
        1070                                        as key_facility,
        count(distinct t.doc_id)                    as transactions
    from ticket_header t
    where t.store_id = '14'
      and t.ticket_day >= cast('2024-01-21' as date)
      and t.doc_id in (select doc_id from mtg_docs)
    group by 1
),

memberships as (
    -- 1080. Legacy start date here is 2023-11-29 (t_fact_cogs uses 2024-01-21).
    select
        t.ticket_day                                as date_key,
        1080                                        as key_facility,
        count(distinct t.doc_id)                    as transactions
    from ticket_header t
    where t.store_id = '14'
      and t.ticket_day >= cast('2023-11-29' as date)
      and t.doc_id in (select doc_id from membership_docs)
    group by 1
),

counted as (
    select * from visitors_center
    union all select * from preview_vesey
    union all select * from museum_store
    union all select * from memorial_carts
    union all select * from atrium
    union all select * from ecommerce
    union all select * from museum_cafe
    union all select * from mag_cart
    union all select * from mus_audio_guide
    union all select * from museum_tour_guides
    union all select * from memberships
)

select
    date_key,
    key_facility,
    transactions
from counted
where date_key is not null
