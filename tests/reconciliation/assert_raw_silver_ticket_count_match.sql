-- Reconciliation: int_pos_tickets count within 1% of raw gateway tickets with sold dates
-- Co-authored with CoCo

with raw_count as (
    select count(*) as cnt
    from {{ source('gateway_seed', 'seed_gate_tickets') }}
    where try_to_timestamp(datesold) is not null
),

int_count as (
    select count(*) as cnt
    from {{ ref('int_pos_tickets') }}
),

reconciliation as (
    select
        r.cnt as raw_cnt,
        s.cnt as int_cnt,
        abs(r.cnt - s.cnt) / nullif(r.cnt, 0) as diff_pct
    from raw_count r, int_count s
)

select raw_cnt, int_cnt, diff_pct
from reconciliation
where diff_pct > 0.01
