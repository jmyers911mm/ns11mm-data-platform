-- Validates that Silver ticket row count is within 1% of RAW source
-- STATUS: Awaiting RAW data connection
-- TODO: Uncomment once RAW.RAW_GATEWAY_TRANSACTIONS is populated

/*
with raw_count as (
    select count(*) as cnt
    from NS11MM_DW_DEV.RAW.RAW_GATEWAY_TRANSACTIONS
),
silver_count as (
    select count(*) as cnt
    from {{ ref('silver_pos_tickets') }}
),
check as (
    select
        r.cnt as raw_cnt,
        s.cnt as silver_cnt,
        abs(r.cnt - s.cnt) / nullif(r.cnt, 0) as diff_pct
    from raw_count r, silver_count s
)
select raw_cnt, silver_cnt, diff_pct
from check
where diff_pct > 0.01
*/
select 1 where 1 = 0  -- placeholder until RAW is populated
