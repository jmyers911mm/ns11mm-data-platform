-- Reconciliation: Silver ticket count within 1% of raw Gateway seed source
-- Co-authored with CoCo

with raw_count as (
    select count(*) as cnt
    from {{ source('gateway_seed', 'seed_gate_jnltickets') }}
),

silver_count as (
    select count(*) as cnt
    from {{ ref('silver_pos_tickets') }}
),

reconciliation as (
    select
        r.cnt as raw_cnt,
        s.cnt as silver_cnt,
        abs(r.cnt - s.cnt) / nullif(r.cnt, 0) as diff_pct
    from raw_count r, silver_count s
)

select raw_cnt, silver_cnt, diff_pct
from reconciliation
where diff_pct > 0.01
