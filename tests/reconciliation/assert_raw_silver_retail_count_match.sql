-- Validates that Silver retail row count is within 1% of RAW source
-- STATUS: Awaiting RAW data connection
/*
with raw_count as (
    select count(*) as cnt
    from NS11MM_DW_DEV.RAW.RAW_COUNTERPOINT_TRANSACTIONS
),
silver_count as (
    select count(*) as cnt
    from {{ ref('silver_pos_retail') }}
),
check as (
    select abs(r.cnt - s.cnt) / nullif(r.cnt, 0) as diff_pct
    from raw_count r, silver_count s
)
select diff_pct from check where diff_pct > 0.01
*/
select 1 where 1 = 0
