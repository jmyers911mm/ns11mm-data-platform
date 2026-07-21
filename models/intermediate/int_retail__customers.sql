{{ config(materialized='view') }}

-- Silver intermediate: retail customer / transaction counts
-- ---------------------------------------------------------------------------
-- Domain: retail
-- Grain:  one row per business_date x key_facility
--
-- Replaces legacy 911dw.fact_num_tickets (t_fact_num_tickets from ps_tkt_hist +
-- ps_tkt_hist_lin). Counts distinct retail transactions per selling area.
--
-- NOTE ON GRAIN: transaction counts are a COUNT(DISTINCT) and are therefore
-- NOT additive across category, which is why they live here at the facility
-- grain rather than in int_retail__performance (category grain). The Retail
-- Performance Report's customers_mus_store / customers_mem_cart /
-- cafe1_transactions all resolve to this measure per facility.

with lines as (
    select * from {{ ref('int_counterpoint__retail_lines') }}
),

counted as (
    select
        cast(business_date as date)                 as date_key,
        key_facility,
        count(distinct doc_id)                      as transactions
    from lines
    where line_type = 'S'          -- count selling transactions, not return-only docs
    group by 1, 2
)

select * from counted
