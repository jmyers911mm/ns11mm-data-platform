/*
Daily data quality check: red / yellow / green for yesterday, plus an N-day trend

One statement: paste into a Snowsight worksheet and run it. One row per check, reds first. Read-only: it only selects.

status    G, Y or R for the as-of date (yesterday, Eastern, by default)
reason    why it is Y or R; blank when green
trend     one letter per day, oldest on the left, as-of date on the right. "-" means the check had nothing to say that day.
trend_json the same days as an array of {date, status, value, typical, reason}, oldest first.
        Flatten it with: select r.check_id, t.value:date::date as dt, t.value:status::string as status from <these results> r, lateral flatten(input => r.trend_json) t;

Databases: marts read from NS11MM_DW_PROD; RAW reads from NS11MM_DW_DEV, the single shared source database (ADR-019). Find and replace if that changes.
*/

with settings as (
    select
        28                                                                          as n_days,
        dateadd(day, -1, convert_timezone('America/New_York', current_timestamp())::date) as as_of
),

params as (
    select
        as_of,
        dateadd(day, -(n_days - 1), as_of)   as trend_start,
        dateadd(day, -(n_days + 55), as_of)  as history_start
    from settings
),

days as (
    select dateadd(day, row_number() over (order by seq4()) - 1, p.history_start) as d
    from table(generator(rowcount => 400)), params p
    qualify d <= (select as_of from params)
),

-- facts, one row per day
dpr as (
    select
        date_key,
        count(*)                        as row_count,
        sum(tickets_sold)               as tickets_sold,
        sum(ticket_revenue)             as ticket_revenue,
        sum(mus_attendance)             as mus_attendance,
        sum(mem_attendance)             as mem_attendance,
        count_if(tickets_sold is null or ticket_revenue is null) as null_key_measures,
        boolor_agg(is_museum_closed_day) as closed
    from NS11MM_DW_PROD.MARTS.FCT_DAILY_PERFORMANCE, params p
    where date_key between p.history_start and p.as_of
    group by 1
),

scan as (
    select
        date_key,
        sum(passes_scanned)                     as passes_scanned,
        count(*) - count(distinct segment_key)  as dup_rows
    from NS11MM_DW_PROD.MARTS.FCT_DAILY_SCAN, params p
    where date_key between p.history_start and p.as_of
    group by 1
),

retail as (
    select
        date_key,
        sum(net_sales)                          as net_sales,
        sum(transactions)                       as transactions,
        count(*) - count(distinct key_facility) as dup_rows
    from NS11MM_DW_PROD.MARTS.FCT_RETAIL_DAILY, params p
    where date_key between p.history_start and p.as_of
    group by 1
),

-- volume checks
-- Each day is compared with the median of the same weekday over the 8 weeks before it. Thresholds are the share it can move before turning Y or R.
metric_values as (
    select 'VOL-01' as check_id, 'Tickets sold'          as check_name, 'FCT_DAILY_PERFORMANCE.TICKETS_SOLD'   as object_name,
           d.d as dt, dpr.tickets_sold   as value, false as closed, 'R' as missing_status, 0.25 as warn_pct, 0.50 as fail_pct
    from days d left join dpr on dpr.date_key = d.d
    union all
    select 'VOL-02', 'Ticket revenue',              'FCT_DAILY_PERFORMANCE.TICKET_REVENUE',
           d.d, dpr.ticket_revenue, false, 'R', 0.25, 0.50
    from days d left join dpr on dpr.date_key = d.d
    union all
    select 'VOL-03', 'Museum attendance',           'FCT_DAILY_PERFORMANCE.MUS_ATTENDANCE',
           d.d, dpr.mus_attendance, coalesce(dpr.closed, false), 'R', 0.25, 0.50
    from days d left join dpr on dpr.date_key = d.d
    union all
    -- NULL here is by design when the memorial feed has no row, so missing is Y, not R
    select 'VOL-04', 'Memorial attendance',         'FCT_DAILY_PERFORMANCE.MEM_ATTENDANCE',
           d.d, dpr.mem_attendance, false, 'Y', 0.25, 0.50
    from days d left join dpr on dpr.date_key = d.d
    union all
    select 'VOL-05', 'Passes scanned',              'FCT_DAILY_SCAN.PASSES_SCANNED',
           d.d, scan.passes_scanned, coalesce(dpr.closed, false), 'R', 0.25, 0.50
    from days d left join scan on scan.date_key = d.d left join dpr on dpr.date_key = d.d
    union all
    select 'VOL-06', 'Retail net sales',            'FCT_RETAIL_DAILY.NET_SALES',
           d.d, retail.net_sales, false, 'R', 0.30, 0.60
    from days d left join retail on retail.date_key = d.d
    union all
    select 'VOL-07', 'Retail transactions',         'FCT_RETAIL_DAILY.TRANSACTIONS',
           d.d, retail.transactions, false, 'R', 0.30, 0.60
    from days d left join retail on retail.date_key = d.d
),

baselines as (
    select
        a.check_id, a.dt,
        median(b.value)  as baseline,
        count(b.value)   as baseline_days
    from metric_values a
    join params p on a.dt >= p.trend_start
    left join metric_values b
        on  b.check_id = a.check_id
        and b.dt <  a.dt
        and b.dt >= dateadd(day, -56, a.dt)
        and dayofweek(b.dt) = dayofweek(a.dt)
        and b.value is not null
        and not b.closed
    group by 1, 2
),

volume as (
    select
        'Volume' as category, m.check_id, m.check_name, m.object_name, m.dt, m.value, b.baseline,
        case
            when m.value is null                                   then m.missing_status
            when m.closed                                          then 'G'
            when b.baseline_days < 3                               then 'Y'
            when b.baseline = 0 and m.value = 0                    then 'G'
            when m.value = 0                                       then 'R'
            when abs(m.value - b.baseline) / nullif(abs(b.baseline), 0) >= m.fail_pct then 'R'
            when abs(m.value - b.baseline) / nullif(abs(b.baseline), 0) >= m.warn_pct then 'Y'
            else 'G'
        end as status,
        case
            when m.value is null        then 'No value for ' || to_char(m.dt, 'Dy Mon DD') || '. The load or the build did not land.'
            when m.closed               then null
            when b.baseline_days < 3    then 'Only ' || b.baseline_days || ' prior ' || dayname(m.dt) || ' dates to compare against.'
            when b.baseline = 0 and m.value = 0 then null
            when m.value = 0            then 'Zero. A typical ' || dayname(m.dt) || ' is ' || trim(to_char(round(b.baseline), '999,999,999,990')) || '.'
            when abs(m.value - b.baseline) / nullif(abs(b.baseline), 0) >= m.warn_pct
                then round(100 * abs(m.value - b.baseline) / abs(b.baseline)) || '% '
                     || iff(m.value < b.baseline, 'below', 'above') || ' a typical ' || dayname(m.dt) || ' ('
                     || trim(to_char(round(m.value), '999,999,999,990')) || ' vs '
                     || trim(to_char(round(b.baseline), '999,999,999,990')) || ').'
        end as reason
    from metric_values m
    join baselines b on b.check_id = m.check_id and b.dt = m.dt
),

-- integrity checks
integrity as (
    select 'Integrity' as category, 'INT-01' as check_id, 'DPR one row per day' as check_name,
           'FCT_DAILY_PERFORMANCE' as object_name, d.d as dt, dpr.row_count as value, null::number as baseline,
           iff(coalesce(dpr.row_count, 0) > 1, 'R', 'G') as status,
           iff(coalesce(dpr.row_count, 0) > 1, dpr.row_count || ' rows for one date. The grain broke.', null) as reason
    from days d left join dpr on dpr.date_key = d.d
    union all
    select 'Integrity', 'INT-02', 'DPR key measures not null', 'FCT_DAILY_PERFORMANCE', d.d, dpr.null_key_measures, null,
           iff(coalesce(dpr.null_key_measures, 0) > 0, 'R', 'G'),
           iff(coalesce(dpr.null_key_measures, 0) > 0, 'Tickets sold or ticket revenue is NULL.', null)
    from days d left join dpr on dpr.date_key = d.d
    union all
    select 'Integrity', 'INT-03', 'Scan one row per segment', 'FCT_DAILY_SCAN', d.d, scan.dup_rows, null,
           iff(coalesce(scan.dup_rows, 0) > 0, 'R', 'G'),
           iff(coalesce(scan.dup_rows, 0) > 0, scan.dup_rows || ' duplicate date x segment rows.', null)
    from days d left join scan on scan.date_key = d.d
    union all
    select 'Integrity', 'INT-04', 'Retail one row per facility', 'FCT_RETAIL_DAILY', d.d, retail.dup_rows, null,
           iff(coalesce(retail.dup_rows, 0) > 0, 'R', 'G'),
           iff(coalesce(retail.dup_rows, 0) > 0, retail.dup_rows || ' duplicate date x facility rows.', null)
    from days d left join retail on retail.date_key = d.d
),

-- reconciliation
-- Same comparison as tests/reconciliation/assert_retail_dpr_cross_chain_reconciliation.sql: Museum Store net sales through the Retail chain vs the DPR chain. Y past 0.5% (the dbt test's tolerance), R past 2%.
rec_retail_chain as (
    select pf.date_key, sum(pf.net_sales) as net_sales
    from NS11MM_DW_PROD.INTERMEDIATE.INT_RETAIL__PERFORMANCE pf
    join NS11MM_DW_DEV.SEEDS.SEED_FACILITY_AREA fa on pf.key_facility = fa.key_facility
    join params p on pf.date_key between p.trend_start and p.as_of
    where fa.facility_group = 'museum_store'
    group by 1
),

rec_dpr_chain as (
    select cast(r.business_date as date) as date_key,
           sum(iff(r.facility_group = 'museum_store' and not r.is_donation, r.net_amount, 0)) as net_sales
    from NS11MM_DW_PROD.INTERMEDIATE.INT_COUNTERPOINT__RETAIL_LINES r
    join params p on cast(r.business_date as date) between p.trend_start and p.as_of
    group by 1
),

reconciliation as (
    select
        'Reconciliation' as category, 'REC-01' as check_id, 'Museum Store sales, Retail vs DPR chain' as check_name,
        'INT_RETAIL__PERFORMANCE vs INT_COUNTERPOINT__RETAIL_LINES' as object_name,
        d.d as dt,
        coalesce(rc.net_sales, 0) - coalesce(dc.net_sales, 0) as value,
        dc.net_sales as baseline,
        case
            when rc.net_sales is null and dc.net_sales is null then null
            when abs(coalesce(rc.net_sales, 0) - coalesce(dc.net_sales, 0)) / nullif(abs(dc.net_sales), 0) > 0.02  then 'R'
            when abs(coalesce(rc.net_sales, 0) - coalesce(dc.net_sales, 0)) / nullif(abs(dc.net_sales), 0) > 0.005 then 'Y'
            when coalesce(dc.net_sales, 0) = 0 and coalesce(rc.net_sales, 0) <> 0 then 'R'
            else 'G'
        end as status,
        case
            when abs(coalesce(rc.net_sales, 0) - coalesce(dc.net_sales, 0)) / nullif(abs(dc.net_sales), 0) > 0.005
                then 'Chains differ by ' || round(100 * abs(coalesce(rc.net_sales, 0) - dc.net_sales) / abs(dc.net_sales), 1)
                     || '% ($' || trim(to_char(round(coalesce(rc.net_sales, 0)), '999,999,990')) || ' vs $'
                     || trim(to_char(round(dc.net_sales), '999,999,990')) || ').'
            when coalesce(dc.net_sales, 0) = 0 and coalesce(rc.net_sales, 0) <> 0
                then 'Retail chain has sales; DPR chain has none.'
        end as reason
    from days d
    join params p on d.d >= p.trend_start
    left join rec_retail_chain rc on rc.date_key = d.d
    left join rec_dpr_chain    dc on dc.date_key = d.d
),

-- roll the daily checks up
daily as (
    select category, check_id, check_name, object_name, dt, value, baseline, status, reason from volume
    union all
    select category, check_id, check_name, object_name, dt, value, baseline, status, reason from integrity
    union all
    select category, check_id, check_name, object_name, dt, value, baseline, status, reason from reconciliation
),

daily_rollup as (
    select
        category, check_id, check_name, object_name,
        max(iff(dt = p.as_of, status, null))   as status,
        max(iff(dt = p.as_of, reason, null))   as reason,
        max(iff(dt = p.as_of, value, null))    as value,
        max(iff(dt = p.as_of, baseline, null)) as typical,
        listagg(coalesce(status, '-'), '') within group (order by dt) as trend,
        array_agg(object_construct_keep_null(
            'date',    to_char(dl.dt, 'YYYY-MM-DD'),
            'status',  dl.status,
            'value',   dl.value,
            'typical', dl.baseline,
            'reason',  dl.reason
        )) within group (order by dt)                                 as trend_json,
        count_if(status = 'R') as red_days,
        count_if(status = 'Y') as yellow_days,
        count_if(status = 'G') as green_days,
        max(iff(status = 'R', dt, null))       as last_red
    from daily dl
    join params p on dl.dt between p.trend_start and p.as_of
    group by 1, 2, 3, 4
),

-- source freshness (today only)
-- Hours since each RAW table last loaded, against the dbt source SLAs. RAW keeps no load history here, so these have no trend.
loads as (
    select 'FRS-01' as check_id, 'gateway' as grp, 'SEED_GATE_JNLTICKETS' as tbl, max(_loaded_at) as loaded_at, 7 as warn_d, 14 as err_d from NS11MM_DW_DEV.RAW.SEED_GATE_JNLTICKETS
    union all select 'FRS-02', 'gateway',       'SEED_GATE_USAGE',              max(_loaded_at), 7, 14 from NS11MM_DW_DEV.RAW.SEED_GATE_USAGE
    union all select 'FRS-03', 'gateway',       'SEED_GATE_ORDERS',             max(_loaded_at), 7, 14 from NS11MM_DW_DEV.RAW.SEED_GATE_ORDERS
    union all select 'FRS-04', 'counterpoint',  'SEED_CP_PSTKTHIST',            max(_loaded_at), 7, 14 from NS11MM_DW_DEV.RAW.SEED_CP_PSTKTHIST
    union all select 'FRS-05', 'report_estate', 'SEED_FACT_PASSES_BY_HOUR',     max(_loaded_at), 2, 4  from NS11MM_DW_DEV.RAW.SEED_FACT_PASSES_BY_HOUR
    union all select 'FRS-06', 'report_estate', 'SEED_FACT_TODAYS_RETAIL_DATA', max(_loaded_at), 2, 4  from NS11MM_DW_DEV.RAW.SEED_FACT_TODAYS_RETAIL_DATA
    union all select 'FRS-07', 'report_estate', 'SEED_SENSOURCE_VISITORS',      max(_loaded_at), 2, 4  from NS11MM_DW_DEV.RAW.SEED_SENSOURCE_VISITORS
    union all select 'FRS-08', 'report_estate', 'SEED_FACT_SHOPIFY_ORDERS',     max(_loaded_at), 2, 4  from NS11MM_DW_DEV.RAW.SEED_FACT_SHOPIFY_ORDERS
),

freshness as (
    select
        'Freshness' as category, check_id, grp || ' load' as check_name, 'RAW.' || tbl as object_name,
        case
            when loaded_at is null                                                      then 'R'
            when datediff('hour', loaded_at::timestamp_ntz, current_timestamp()::timestamp_ntz) > err_d * 24  then 'R'
            when datediff('hour', loaded_at::timestamp_ntz, current_timestamp()::timestamp_ntz) > warn_d * 24 then 'Y'
            else 'G'
        end as status,
        case
            when loaded_at is null then 'Table is empty or has no _loaded_at.'
            when datediff('hour', loaded_at::timestamp_ntz, current_timestamp()::timestamp_ntz) > warn_d * 24
                then 'Last load ' || round(datediff('hour', loaded_at::timestamp_ntz, current_timestamp()::timestamp_ntz) / 24, 1)
                     || ' days ago (' || to_char(loaded_at, 'Mon DD HH24:MI') || '). SLA warns at '
                     || warn_d || ' days, errors at ' || err_d || '.'
        end as reason,
        round(datediff('hour', loaded_at::timestamp_ntz, current_timestamp()::timestamp_ntz) / 24, 1) as value,
        null::number as typical,
        null as trend, null::array as trend_json, null::number as red_days, null::number as yellow_days, null::number as green_days,
        null::date as last_red
    from loads
)

select
    (select as_of from params)              as as_of,
    status,
    category,
    check_id,
    check_name,
    reason,
    value,
    typical,
    trend,
    trend_json,
    red_days,
    yellow_days,
    green_days,
    last_red,
    object_name
from (
    select category, check_id, check_name, object_name, status, reason, value, typical,
           trend, trend_json, red_days, yellow_days, green_days, last_red
    from daily_rollup
    union all
    select category, check_id, check_name, object_name, status, reason, value, typical,
           trend, trend_json, red_days, yellow_days, green_days, last_red
    from freshness
)
order by
    case status when 'R' then 1 when 'Y' then 2 when 'G' then 3 else 4 end,
    red_days desc nulls last,
    check_id;