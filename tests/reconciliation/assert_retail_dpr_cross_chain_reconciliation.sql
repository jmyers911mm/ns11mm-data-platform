-- Test (reconciliation): the two retail lineages agree on Museum Store net sales
-- Severity: warn — promote to error after a clean run on live data
--
-- The Retail Performance chain (int_retail__performance -> fct_retail_performance)
-- and the DPR chain (int_dpr__retail -> fct_daily_performance.mus_store_gross_*)
-- both aggregate int_counterpoint__retail_lines. 7.9.0 centralized the netting
-- convention (net_amount) after the two chains were found netting returns with
-- opposite signs; this test keeps them from ever diverging silently again.
-- Compares day-level Museum Store NET SALES (the shared component both chains
-- carry: DPR's mus_store_gross_profit = mus_store_sales - cost, so sales-side
-- agreement implies the profit lines tie once cost is common) over the last
-- 30 days, tolerance 0.5%.

{{ config(severity='warn') }}

with retail_chain as (
    select
        p.date_key,
        sum(p.net_sales) as net_sales
    from {{ ref('int_retail__performance') }} p
    join {{ ref('seed_facility_area') }} fa
        on p.key_facility = fa.key_facility
    where fa.facility_group = 'museum_store'
      and p.date_key >= dateadd(day, -30, current_date)
    group by 1
),

dpr_chain as (
    select
        cast(r.business_date as date) as date_key,
        sum(case when r.facility_group = 'museum_store' and not r.is_donation
                 then r.net_amount else 0 end) as net_sales
    from {{ ref('int_counterpoint__retail_lines') }} r
    where cast(r.business_date as date) >= dateadd(day, -30, current_date)
    group by 1
),

compared as (
    select
        coalesce(rc.date_key, dc.date_key)             as date_key,
        coalesce(rc.net_sales, 0)                      as retail_chain_net_sales,
        coalesce(dc.net_sales, 0)                      as dpr_chain_net_sales,
        abs(coalesce(rc.net_sales, 0) - coalesce(dc.net_sales, 0))
            / nullif(abs(coalesce(dc.net_sales, 0)), 0) as diff_pct
    from retail_chain rc
    full outer join dpr_chain dc on rc.date_key = dc.date_key
)

select *
from compared
where diff_pct > 0.005
