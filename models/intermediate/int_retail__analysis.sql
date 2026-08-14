-- Silver intermediate: Retail Analysis Report measures, facility-day
-- ---------------------------------------------------------------------------
-- Domain: retail
-- Grain:  one row per date_key x key_facility
--
-- The platform equivalent of legacy 911dw.fact_retail_analysis. Carries the
-- additive components every measure the Retail Analysis workbook prints is
-- built from -- visitors, customers, sales, cost, gross profit, units, the two
-- attendance denominators, and the water carve-out -- and carries NO quotient.
-- Capture rate, conversion rate, average sale and profit-per-customer are
-- recomputed as ratio-of-sums at display grain from the pairs below.
-- Feeds fct_retail_analysis, and through it the Retail Analysis serving stack
-- plus the four already-migrated reports that read fact_retail_analysis today.
--
-- The ratio DENOMINATORS and the door counts are read from
-- int_retail__ratio_components (8.5.0), the single authoring site for retail
-- ratio pairs -- they are not re-derived here:
--   visitors            = store_entries       (Sensource, crosswalked in 8.4.0)
--   customers           = transactions        (int_retail__customers cohorts)
--   museum_attendance   = passes scanned at reporting facility 1030 (1006+3000)
--   memorial_attendance = passes scanned at reporting facility 2000
--
-- What IS authored here, and only here, is the exclusion-scoped money. The
-- Retail Analysis series is NOT the Retail Performance series: every legacy
-- sales branch carries
--     key_summary_category <> '6' AND key_item_descr NOT IN ('2449'..'2454')
-- so membership sales are removed from Museum Store / Memorial Carts / Vesey
-- revenue and reported separately at facility 1080. int_retail__performance
-- applies no such exclusion, so `sales_amount` here is deliberately NOT
-- `int_retail__performance.net_sales` and the two must not be substituted for
-- one another (see the reconciliation test shipped with 8.10.0).
--
-- LEGACY ASYMMETRY, reproduced verbatim: the exclusion is applied to SALES
-- (t_fact_retail) and NOT to COST (t_fact_cogs sums Cost for the facility with
-- no item filter at t_fact_mus_store_analysis.sql:83-91 and :200-205). So
-- gross_profit = sales-excluding-memberships minus cost-including-memberships.
-- That is what the certified series has always computed; it is not corrected
-- here.
--
-- Legacy lineage: t_fact_mus_store_analysis (911dw.fact_retail_analysis, six
-- InsertUpdate steps), t_reporting_mus_store_profit, t_reporting_mem_cart_profit.
-- STATUS: water_* is a typed NULL -- blocked on a business rule. The legacy
-- carve-out selects key_item_descr = 4636, a surrogate over the item
-- DESCRIPTION in 911dw.dim_item_descr, and no captured transformation resolves
-- it to a CounterPoint item_no. seed_retail_water_item carries the unresolved
-- key; the guard below flips the column from NULL to a real measure the moment
-- is_resolved is set, with no SQL change.
-- STATUS: medallion_* is a typed NULL -- no data feed. 911dw.medallion_machine
-- has no writer among the 216 captured transformations and no staged source.
-- SCOPE NOTE: ADR-005. museum_attendance / memorial_attendance inherit 8.5.0's
-- gate -- they are the Sensource passes-scanned measures, not the DPR scan
-- component. Owners: Gennady Zaritsky, Chris Wogas.
--
-- ADR-021 ratio rule: numerator and denominator are carried as separate
-- additive columns; the division happens once, at display grain.

{{ config(materialized='view') }}

with ratio_components as (
    select * from {{ ref('int_retail__ratio_components') }}
),

lines as (
    select * from {{ ref('int_counterpoint__retail_lines') }}
),

item_master as (
    select * from {{ ref('stg_counterpoint__imitem') }}
),

excluded_item as (
    select * from {{ ref('seed_retail_analysis_excluded_item') }}
    where is_resolved
),

water_item as (
    select * from {{ ref('seed_retail_water_item') }}
    where is_resolved
      and water_group = 'retail_analysis_carve_out'
),

-- Legacy excludes on key_item_descr, a surrogate whose NATURAL KEY is the item
-- description text, not item_no: t_dim_item_desc loads dim_item_descr from
-- IM_ITEM.DESCR and t_dim_item_desc_from_ecommerce loads the same dimension
-- from uc_order_products.title, which carries no item number at all. So two
-- SKUs sharing a description share one key_item_descr and legacy excludes both.
-- Resolving the seeded item_no back to its description and matching on the
-- description reproduces that behaviour; matching on item_no alone would miss a
-- retired SKU that carried the same description under a different number.
excluded_description as (
    select distinct upper(trim(im.description))     as description_key
    from item_master im
    inner join excluded_item e
        on cast(im.item_no as varchar) = cast(e.item_no as varchar)
    where nullif(trim(im.description), '') is not null
),

water_description as (
    select distinct upper(trim(im.description))     as description_key
    from item_master im
    inner join water_item w
        on cast(im.item_no as varchar) = cast(w.item_no as varchar)
    where nullif(trim(im.description), '') is not null
),

-- One row, one boolean. Drives the typed-NULL guard on the water columns so an
-- unresolved seed yields NULL rather than a zero-filled measure.
water_resolution as (
    select count(*) > 0                             as is_water_resolved
    from water_item
),

water_window as (
    select min(valid_from)                          as water_valid_from
    from water_item
),

-- Flag each line. NOT filtered on is_primary_facility: legacy runs one query
-- per facility and this model reports per facility, so the many-to-many scope
-- fan-out in int_counterpoint__retail_lines is correct here (see that model's
-- header). Only a cross-facility total would need the primary filter.
flagged as (
    select
        cast(l.business_date as date)               as date_key,
        l.key_facility,
        l.is_donation,
        l.net_amount,
        l.net_cost,
        l.net_quantity,
        (ei.item_no is not null or ed.description_key is not null)  as is_excluded_item,
        (wi.item_no is not null or wd.description_key is not null)  as is_water_item
    from lines l
    left join excluded_item ei
        on cast(l.item_no as varchar) = cast(ei.item_no as varchar)
    left join excluded_description ed
        on upper(trim(l.item_description)) = ed.description_key
    left join water_item wi
        on cast(l.item_no as varchar) = cast(wi.item_no as varchar)
    left join water_description wd
        on upper(trim(l.item_description)) = wd.description_key
),

-- Facility-day money. Sales and units carry BOTH legacy filters; cost carries
-- neither (see LEGACY ASYMMETRY in the header).
money as (
    select
        f.date_key,
        f.key_facility,

        sum(case when not f.is_donation and not f.is_excluded_item
                 then f.net_amount else 0 end)                      as sales_amount,
        sum(case when not f.is_donation and not f.is_excluded_item
                 then f.net_quantity else 0 end)                    as units_sold,
        sum(f.net_cost)                                             as cost_amount,

        -- Water carve-out: (Amount + Return_Amount) - Cost over the water SKUs,
        -- non-donation, from the seeded start date. Zero rows until the seed
        -- resolves; the projection below turns that into a typed NULL.
        sum(case when f.is_water_item and not f.is_donation
                  and f.date_key >= ww.water_valid_from
                 then f.net_amount else 0 end)                      as water_sales,
        sum(case when f.is_water_item and not f.is_donation
                  and f.date_key >= ww.water_valid_from
                 then f.net_cost else 0 end)                        as water_cost

    from flagged f
    cross join water_window ww
    group by 1, 2
),

combined as (
    select
        rc.date_key,
        rc.key_facility,

        -- Ratio components read from the 8.5.0 authoring site, never re-derived
        rc.store_entries                                            as visitors,
        rc.transactions                                             as customers,
        rc.museum_attendance,
        rc.memorial_attendance,

        coalesce(m.sales_amount, 0)                                 as sales_amount,
        coalesce(m.cost_amount, 0)                                  as cost_amount,
        coalesce(m.sales_amount, 0) - coalesce(m.cost_amount, 0)    as gross_profit,
        coalesce(m.units_sold, 0)                                   as units_sold,

        m.water_sales,
        m.water_cost,

        wr.is_water_resolved

    from ratio_components rc
    left join money m
        on rc.date_key = m.date_key
       and rc.key_facility = m.key_facility
    cross join water_resolution wr
)

select
    date_key,
    key_facility,

    -- Additive counts (capture numerator / conversion denominator, and the
    -- conversion numerator)
    visitors,
    customers,

    -- Day-level denominators, repeated on every facility row so each ratio's
    -- pair travels together at this grain
    museum_attendance,
    memorial_attendance,

    -- Additive money, exclusion-scoped per the header
    sales_amount,
    cost_amount,
    gross_profit,
    units_sold,

    -- Water carve-out. Typed NULL + stated cause while the legacy
    -- key_item_descr 4636 is unresolved (blocked on a business rule); becomes a
    -- real measure with no SQL change once seed_retail_water_item.is_resolved
    -- is set.
    case when is_water_resolved then coalesce(water_sales, 0)
         else cast(null as number(38, 4)) end               as water_sales,
    case when is_water_resolved then coalesce(water_cost, 0)
         else cast(null as number(38, 4)) end               as water_cost,
    case when is_water_resolved then coalesce(water_sales, 0) - coalesce(water_cost, 0)
         else cast(null as number(38, 4)) end               as water_gross_profit,

    -- Medallion machine. Typed NULL + stated cause: no data feed.
    -- 911dw.medallion_machine (t_fact_mus_store_analysis.sql:119-124) has no
    -- writer in the captured Pentaho set and no staged equivalent.
    cast(null as number(38, 4))                             as medallion_sales,
    cast(null as number(38, 4))                             as medallion_profit,
    cast(null as number(38, 4))                             as medallion_units_sold

from combined
