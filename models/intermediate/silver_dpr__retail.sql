-- Silver DPR: retail gross profit, MUS AG, and retail-sourced donations
-- ---------------------------------------------------------------------------
-- Domain: retail
-- Grain:  one row per business_date (aliased key_date)
--
-- Recreates the CounterPoint-sourced DPR line items from the retail-line
-- silver model. Gross profit = sales - cost; donations are the summary-
-- category-6 lines at specific facilities/items.
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
    select * from {{ ref('silver_counterpoint__retail_lines') }}
),

daily as (
    select
        cast(business_date as date)                                        as key_date,

        -- Museum Store gross profit (fac 1003, non-donation summary category)
        sum(case when key_facility = 1003 and summary_category <> 6
                 then sale_amount + return_amount else 0 end)              as mus_store_sales,
        sum(case when key_facility = 1003 and summary_category <> 6
                 then sale_cost else 0 end)                                as mus_store_cost,

        -- Memorial Carts gross profit (fac 1020, non-donation)
        sum(case when key_facility = 1020 and summary_category <> 6
                 then sale_amount + return_amount else 0 end)              as mem_cart_sales,
        sum(case when key_facility = 1020 and summary_category <> 6
                 then sale_cost else 0 end)                                as mem_cart_cost,

        -- Cafe gross profit (fac 4007, non-donation)
        sum(case when key_facility = 4007 and summary_category <> 6
                 then sale_amount + return_amount else 0 end)              as cafe1_sales,
        sum(case when key_facility = 4007 and summary_category <> 6
                 then sale_cost else 0 end)                                as cafe1_cost,

        -- MUS AG (fac 1060) profit + units for the audio_tour_headset roll-up
        sum(case when key_facility = 1060 and summary_category <> 6
                 then sale_amount + return_amount else 0 end)              as musag_sales,
        sum(case when key_facility = 1060 and summary_category <> 6
                 then sale_cost else 0 end)                                as musag_cost,
        sum(case when key_facility = 1060 and summary_category <> 6
                 then sale_quantity + return_quantity else 0 end)          as musag_units,

        -- Retail-sourced donations (summary category 6)
        sum(case when key_facility = 1003 and summary_category = 6
                 then sale_amount + return_amount else 0 end)              as mus_store_donations,
        sum(case when key_facility = 1020 and summary_category = 6
                 then sale_amount + return_amount else 0 end)              as cart_donation_ask,
        sum(case when key_facility = 1003 and item_no = '886'
                 then sale_amount + return_amount else 0 end)              as mus_exit_donations,
        sum(case when key_facility = 1234 and summary_category = 6
                 then sale_amount + return_amount else 0 end)              as ecom_donation_ask,
        sum(case when key_facility = 4007 and summary_category = 6
                 then sale_amount + return_amount else 0 end)              as cafe1_donations

    from retail
    group by business_date
)

select
    key_date,

    -- Gross profit line items (sales - cost)
    mus_store_sales - mus_store_cost                                       as mus_store_gross_profit,
    mem_cart_sales  - mem_cart_cost                                        as retail_carts_gross_profit,
    cafe1_sales     - cafe1_cost                                           as cafe1_all_profit,

    -- MUS AG components (added to Galaxy audio revenue in the mart)
    musag_sales - musag_cost                                               as musag_profit,
    musag_units,

    -- Donation line items
    mus_store_donations,
    cart_donation_ask,
    mus_exit_donations,
    ecom_donation_ask,
    cafe1_donations

from daily
