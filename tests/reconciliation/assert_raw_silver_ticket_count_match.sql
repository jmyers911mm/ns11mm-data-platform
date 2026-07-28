-- Test (reconciliation): int_pos_tickets count within 1% of deduped staging tickets (sold)
-- Co-authored with CoCo
-- Severity: error — drift beyond tolerance means silver dropped or duplicated rows

with stg_count as (
    select count(*) as cnt
    from {{ ref('stg_gateway__tickets') }}
    where sold_at is not null
),

int_count as (
    select count(*) as cnt
    from {{ ref('int_pos_tickets') }}
),

reconciliation as (
    select
        r.cnt as stg_cnt,
        s.cnt as int_cnt,
        abs(r.cnt - s.cnt) / nullif(r.cnt, 0) as diff_pct
    from stg_count r, int_count s
)

select stg_cnt, int_cnt, diff_pct
from reconciliation
where diff_pct > 0.01
