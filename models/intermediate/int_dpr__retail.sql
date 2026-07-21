-- Silver DPR: retail gross profit, MUS AG, and retail-sourced donations
-- ---------------------------------------------------------------------------
-- Domain: retail
-- Grain:  one row per business_date (aliased date_key)
--
-- Recreates the CounterPoint-sourced DPR line items from the retail-line
-- silver model. Gross profit = sales - cost; donations are the summary-
-- category-6 lines at specific facilities/items.
--
-- Facility selection and the donation flag come from int_counterpoint__retail_lines
-- as facility_group / is_donation, so this model no longer hardcodes facility
-- numbers (1003, 1020, ...) or the donation category (= 6). Item-level donation
-- products are still selected by item_no because they are specific SKUs, not a
-- facility cohort.
--
-- Legacy lineage: t_reporting_mus_store_profit, t_reporting_mem_cart_profit,
-- t_reporting_museum_audio_headset_revenue (CounterPoint portion, fac 1060),
-- t_reporting_mus_donation_box (fact_retail item 886 at Museum Store),
-- t_reporting_cart_ask (fact_retail item 483 at Memorial Carts),
-- t_reporting_cafe_revenue_donations, and fact_cogs.
--
-- Item-descr codes (legacy key_item_descr, resolved to item_no here):
--   483  -> Retail cart donation ask (Memorial Carts, fac 1020)
--   886  -> Museum exit donation (Museum Store, fac 1003)
-- These are legacy dim_item_descr surrogate keys; confirm the CounterPoint
-- item_no equivalents with Gennady Zaritsky before go-live (build note).

{{ config(materialized='view') }}

with retail as (
    select * from {{ ref('int_counterpoint__retail_lines') }}
),

daily as (
    select
        cast(business_date as date)                                        as date_key,

        -- Museum Store gross profit (non-donation summary category)
        sum(case when facility_group = 'museum_store' and not is_donation
                 then sale_amount + return_amount else 0 end)              as mus_store_sales,
        sum(case when facility_group = 'museum_store' and not is_donation
                 then sale_cost else 0 end)                                as mus_store_cost,

        -- Memorial Carts gross profit (non-donation)
        sum(case when facility_group = 'memorial_carts' and not is_donation
                 then sale_amount + return_amount else 0 end)              as mem_cart_sales,
        sum(case when facility_group = 'memorial_carts' and not is_donation
                 then sale_cost else 0 end)                                as mem_cart_cost,

        -- Cafe gross profit (non-donation)
        sum(case when facility_group = 'museum_cafe' and not is_donation
                 then sale_amount + return_amount else 0 end)              as cafe1_sales,
        sum(case when facility_group = 'museum_cafe' and not is_donation
                 then sale_cost else 0 end)                                as cafe1_cost,

        -- Memorial Audio Guide, CounterPoint portion (mag_cart = item 201114
        -- via seed_retail_item_facility). Primary MAG source since 2023;
        -- previously carved out of the carts but aggregated NOWHERE, so the
        -- mart undercounted mem_audio_guide_revenue (Galaxy %MAG% only).
        sum(case when facility_group = 'mag_cart' and not is_donation
                 then sale_amount + return_amount else 0 end)              as mag_cp_revenue,

        -- MUS AG profit + units for the audio_tour_headset roll-up
        sum(case when facility_group = 'mus_ag' and not is_donation
                 then sale_amount + return_amount else 0 end)              as musag_sales,
        sum(case when facility_group = 'mus_ag' and not is_donation
                 then sale_cost else 0 end)                                as musag_cost,
        sum(case when facility_group = 'mus_ag' and not is_donation
                 then sale_quantity + return_quantity else 0 end)          as musag_units,

        -- Retail-sourced donations (summary category 6 -> is_donation)
        -- Surrogate keys resolved by inspection 2026-07-08 (legacy dim_item_descr
        -- key -> real CounterPoint item_no): 483 -> '7-999' (Donation Ask),
        -- 886 -> '101375' (Donation Box Store Exit). item_no is alphanumeric,
        -- which is why the numeric surrogates could never match.
        -- mus_store_donations excludes the exit-box item so it does not
        -- double-count mus_exit_donations (legacy item list excludes 886).
        sum(case when facility_group = 'museum_store' and is_donation
                  and item_no <> '101375'
                 then sale_amount + return_amount else 0 end)              as mus_store_donations,
        -- Cart ask narrowed to the Donation Ask item (legacy 483 at stores
        -- 11-14); the former all-cat-6 filter would double-count the plaza
        -- donation box (101165) now measured separately as donation_box.
        sum(case when facility_group = 'memorial_carts' and is_donation
                  and item_no = '7-999'
                 then sale_amount + return_amount else 0 end)              as cart_donation_ask,
        sum(case when facility_group = 'museum_store' and item_no = '101375'
                 then sale_amount + return_amount else 0 end)              as mus_exit_donations,
        sum(case when facility_group = 'ecommerce' and is_donation
                 then sale_amount + return_amount else 0 end)              as ecom_donation_ask,
        sum(case when facility_group = 'museum_cafe' and is_donation
                 then sale_amount + return_amount else 0 end)              as cafe1_donations,

        -- Mask donations: CounterPoint item 200704 (legacy dim_item_descr 4618).
        -- Re-pointed from the Gateway item journal 2026-07-08; correct source
        -- per legacy spec. Dormant since 2021 so zeros are expected.
        sum(case when item_no = '200704'
                 then sale_amount + return_amount else 0 end)              as mask_donations,

        -- Plaza donation box: CounterPoint item 101165 (legacy dim_item_descr
        -- 3375). Re-pointed from the Gateway item journal 2026-07-08;
        -- verified live (PLAZA DONATION BOX, $2,059 net Jun-Jul 2026).
        sum(case when item_no = '101165'
                 then sale_amount + return_amount else 0 end)              as donation_box

    from retail
    group by business_date
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