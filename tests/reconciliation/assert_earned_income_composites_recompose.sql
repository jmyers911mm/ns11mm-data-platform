-- Test (reconciliation): the two Earned Income composites equal the lines they are made of, on both scenarios
-- Severity: error — TOTAL_TICKETS_SOLD and TOTAL_ADMISSIONS_REVENUE are the two
-- numbers on this report that the CFO reads first, and each is defined as a sum
-- of other printed lines:
--     TOTAL_TICKETS_SOLD       = TICKETS + CITYPASS_TICKETS
--     TOTAL_ADMISSIONS_REVENUE = TICKET_REVENUE + CITYPASS_REVENUE + SERVICE_FEES
-- rpt_earned_income_variance_report_long is the single place either is authored
-- (composites-authored-once). This test is the guard that they stay derived
-- rather than drifting into an independent definition — the exact failure that
-- 8.1.0 removed from TOTAL_RETAIL_GROSS_PROFIT, where actual and budget were
-- built from unlike component sets and the totals silently disagreed.
--
-- It is deliberately run on BOTH scenarios. A composite that reconciles on the
-- actual leg and not on the budget leg is the unlike-totals defect, and it is
-- invisible on the printed workbook because the reader only sees the variance.
--
-- Tolerance is 0.01 to absorb NUMBER(38,4) rounding, not to absorb logic.

with pivoted as (
    select
        report_date,
        sum(case when line_item_code = 'TICKETS'                  then amount end)        as tickets,
        sum(case when line_item_code = 'CITYPASS_TICKETS'         then amount end)        as citypass_tickets,
        sum(case when line_item_code = 'TOTAL_TICKETS_SOLD'       then amount end)        as total_tickets_sold,
        sum(case when line_item_code = 'TICKET_REVENUE'           then amount end)        as ticket_revenue,
        sum(case when line_item_code = 'CITYPASS_REVENUE'         then amount end)        as citypass_revenue,
        sum(case when line_item_code = 'SERVICE_FEES'             then amount end)        as service_fees,
        sum(case when line_item_code = 'TOTAL_ADMISSIONS_REVENUE' then amount end)        as total_admissions_revenue,
        sum(case when line_item_code = 'TICKETS'                  then budget_amount end) as b_tickets,
        sum(case when line_item_code = 'CITYPASS_TICKETS'         then budget_amount end) as b_citypass_tickets,
        sum(case when line_item_code = 'TOTAL_TICKETS_SOLD'       then budget_amount end) as b_total_tickets_sold,
        sum(case when line_item_code = 'TICKET_REVENUE'           then budget_amount end) as b_ticket_revenue,
        sum(case when line_item_code = 'CITYPASS_REVENUE'         then budget_amount end) as b_citypass_revenue,
        sum(case when line_item_code = 'SERVICE_FEES'             then budget_amount end) as b_service_fees,
        sum(case when line_item_code = 'TOTAL_ADMISSIONS_REVENUE' then budget_amount end) as b_total_admissions_revenue,
        -- The ratio line must carry the SAME components the additive lines
        -- carry: a divergence here means the report shows an average ticket
        -- price that its own numerator and denominator lines contradict.
        sum(case when line_item_code = 'AVG_TICKET_PRICE'         then numerator end)     as atp_num,
        sum(case when line_item_code = 'AVG_TICKET_PRICE'         then denominator end)   as atp_den
    from {{ ref('rpt_earned_income_variance_report_long') }}
    group by report_date
)

select
    'actual_total_tickets_sold_does_not_recompose'      as failure,
    report_date,
    total_tickets_sold                                  as reported_total,
    tickets + citypass_tickets                          as recomputed_total
from pivoted
where abs(coalesce(total_tickets_sold, 0) - (coalesce(tickets, 0) + coalesce(citypass_tickets, 0))) > 0.01

union all

select
    'budget_total_tickets_sold_does_not_recompose',
    report_date,
    b_total_tickets_sold,
    b_tickets + b_citypass_tickets
from pivoted
where abs(coalesce(b_total_tickets_sold, 0) - (coalesce(b_tickets, 0) + coalesce(b_citypass_tickets, 0))) > 0.01

union all

select
    'actual_total_admissions_revenue_does_not_recompose',
    report_date,
    total_admissions_revenue,
    ticket_revenue + citypass_revenue + service_fees
from pivoted
where abs(coalesce(total_admissions_revenue, 0)
          - (coalesce(ticket_revenue, 0) + coalesce(citypass_revenue, 0) + coalesce(service_fees, 0))) > 0.01

union all

select
    'budget_total_admissions_revenue_does_not_recompose',
    report_date,
    b_total_admissions_revenue,
    b_ticket_revenue + b_citypass_revenue + b_service_fees
from pivoted
where abs(coalesce(b_total_admissions_revenue, 0)
          - (coalesce(b_ticket_revenue, 0) + coalesce(b_citypass_revenue, 0) + coalesce(b_service_fees, 0))) > 0.01

union all

select
    'avg_ticket_price_components_disagree_with_their_own_lines',
    report_date,
    atp_num,
    ticket_revenue
from pivoted
where abs(coalesce(atp_num, 0) - coalesce(ticket_revenue, 0)) > 0.01
   or abs(coalesce(atp_den, 0) - coalesce(tickets, 0)) > 0.01
