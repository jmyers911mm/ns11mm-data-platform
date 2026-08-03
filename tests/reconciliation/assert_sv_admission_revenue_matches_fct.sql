-- Test (reconciliation): semantic-view admission revenue = governed fct column (day grain)
-- Severity: error — the DPR semantic view restates ticket + pass revenue because a
-- metric name shadows the same-named base column (Snowflake engine limitation, 7.11.2);
-- this test is the guard that keeps that restatement equal to the defined-once
-- fct_daily_performance.total_admission_revenue. If this fails, the fct definition
-- changed and DPR.sv.yaml / UNIFIED.sv.yaml must be updated and re-deployed.

with fact as (
    select date_key, total_admission_revenue
    from {{ ref('fct_daily_performance') }}
),

sv as (
    select report_date, admission_revenue
    from {{ ref('rpt_dpr_powerbi') }}
)

select f.date_key, f.total_admission_revenue, s.admission_revenue
from fact f
inner join sv s on f.date_key = s.report_date
where abs(coalesce(f.total_admission_revenue, 0) - coalesce(s.admission_revenue, 0)) > 0.01
