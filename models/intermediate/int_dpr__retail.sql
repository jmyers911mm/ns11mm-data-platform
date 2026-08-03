-- Silver intermediate: retail gross profit, MUS AG, and retail-sourced donations
-- ---------------------------------------------------------------------------
-- Domain: retail
-- Grain: one row per business_date (aliased date_key)
--
-- Recreates the CounterPoint-sourced DPR line items from the retail-line
-- silver model. Gross profit = sales - cost; donations are the summary-
-- category-6 lines at specific facilities/items.
--
-- Facility selection and the donation flag come from int_counterpoint__retail_lines
-- as facility_group / is_donation, so this model no longer hardcodes facility
-- numbers (1003, 1020, ...) or the donation category (= 6). Donation SKUs are
-- resolved to a donation_line via seed_retail_donation_item (was inline item_no
-- literals) -- edit the seed to re-point a donation product.
--
-- Legacy lineage: t_reporting_mus_store_profit, t_reporting_mem_cart_profit,
-- t_reporting_museum_audio_headset_revenue (CounterPoint portion, fac 1060),
-- t_reporting_mus_donation_box (fact_retail item 886 at Museum Store),
-- t_reporting_cart_ask (fact_retail item 483 at Memorial Carts),
-- t_reporting_cafe_revenue_donations, and fact_cogs.
--
-- Donation SKU roles (seed_retail_donation_item, resolved 2026-07-08):
-- cart_ask -> '7-999' (legacy 483, Donation Ask, Memorial Carts)
-- mus_exit -> '101375' (legacy 886, Donation Box Store Exit)
-- mask -> '200704' (legacy 4618, Mask donations; dormant since 2021)
-- plaza_box -> '101165' (legacy 3375, Plaza donation box)

{{ config(materialized='view') }}

with retail as (
    select * from {{ ref('int_counterpoint__retail_lines') }}
),

donation_item as (
    select item_no, donation_line
    from {{ ref('seed_retail_donation_item') }}
),

daily as (
    select
        cast(r.business_date as date)                                      as date_key,

        -- Museum Store gross profit (non-donation summary category)
        sum(case when r.facility_group = 'museum_store' and not r.is_donation
                 then r.net_amount else 0 end)          as mus_store_sales,
        sum(case when r.facility_group = 'museum_store' and not r.is_donation
                 then r.sale_cost else 0 end)                              as mus_store_cost,

        -- Memorial Carts gross profit (non-donation)
        sum(case when r.facility_group = 'memorial_carts' and not r.is_donation
                 then r.net_amount else 0 end)          as mem_cart_sales,
        sum(case when r.facility_group = 'memorial_carts' and not r.is_donation
                 then r.sale_cost else 0 end)                              as mem_cart_cost,

        -- Cafe gross profit (non-donation)
        sum(case when r.facility_group = 'museum_cafe' and not r.is_donation
                 then r.net_amount else 0 end)          as cafe1_sales,
        sum(case when r.facility_group = 'museum_cafe' and not r.is_donation
                 then r.sale_cost else 0 end)                              as cafe1_cost,

        -- Memorial Audio Guide, CounterPoint portion (mag_cart = item 201114
        -- via seed_retail_item_facility). Primary MAG source since 2023;
        -- previously carved out of the carts but aggregated NOWHERE, so the
        -- mart undercounted mem_audio_guide_revenue (Galaxy %MAG% only).
        sum(case when r.facility_group = 'mag_cart' and not r.is_donation
                 then r.net_amount else 0 end)          as mag_cp_revenue,

        -- MUS AG profit + units for the audio_tour_headset roll-up
        sum(case when r.facility_group = 'mus_ag' and not r.is_donation
                 then r.net_amount else 0 end)          as musag_sales,
        sum(case when r.facility_group = 'mus_ag' and not r.is_donation
                 then r.sale_cost else 0 end)                              as musag_cost,
        sum(case when r.facility_group = 'mus_ag' and not r.is_donation
                 then r.net_quantity else 0 end)      as musag_units,

        -- Retail-sourced donations (summary category 6 -> is_donation), donation
        -- SKUs resolved via seed_retail_donation_item.
        -- mus_store_donations excludes the exit-box item so it does not
        -- double-count mus_exit_donations (legacy item list excludes 886).
        sum(case when r.facility_group = 'museum_store' and r.is_donation
                  and coalesce(di.donation_line, '') <> 'mus_exit'
                 then r.net_amount else 0 end)          as mus_store_donations,
        -- Cart ask narrowed to the Donation Ask item (legacy 483 at stores
        -- 11-14); the former all-cat-6 filter would double-count the plaza
        -- donation box now measured separately as donation_box.
        sum(case when r.facility_group = 'memorial_carts' and r.is_donation
                  and di.donation_line = 'cart_ask'
                 then r.net_amount else 0 end)          as cart_donation_ask,
        sum(case when r.facility_group = 'museum_store' and di.donation_line = 'mus_exit'
                 then r.net_amount else 0 end)          as mus_exit_donations,
        sum(case when r.facility_group = 'ecommerce' and r.is_donation
                 then r.net_amount else 0 end)          as ecom_donation_ask,
        sum(case when r.facility_group = 'museum_cafe' and r.is_donation
                 then r.net_amount else 0 end)          as cafe1_donations,

        -- Mask donations: CounterPoint item 200704 (legacy dim_item_descr 4618).
        -- Re-pointed from the Gateway item journal 2026-07-08; correct source
        -- per legacy spec. Dormant since 2021 so zeros are expected.
        sum(case when di.donation_line = 'mask'
                 then r.net_amount else 0 end)          as mask_donations,

        -- Plaza donation box: CounterPoint item 101165 (legacy dim_item_descr
        -- 3375). Re-pointed from the Gateway item journal 2026-07-08;
        -- verified live (PLAZA DONATION BOX, $2,059 net Jun-Jul 2026).
        sum(case when di.donation_line = 'plaza_box'
                 then r.net_amount else 0 end)          as donation_box

    from retail r
    left join donation_item di
      on cast(r.item_no as varchar) = cast(di.item_no as varchar)
    group by r.business_date
)

select
    date_key,

    -- Gross profit line items (sales - cost)
    mus_store_sales - mus_store_cost                                       as mus_store_gross_profit,
    mem_cart_sales  - mem_cart_cost                                        as retail_carts_gross_profit,
    cafe1_sales     - cafe1_cost                                           as cafe1_all_profit,

    -- MUS AG components (added to Galaxy audio revenue in the mart)
    musag_sales - musag_cost                                               as musag_profit,
    musag_units,
    mag_cp_revenue,

    -- Donation line items
    mus_store_donations,
    cart_donation_ask,
    mus_exit_donations,
    ecom_donation_ask,
    cafe1_donations,
    mask_donations,
    donation_box

from daily
