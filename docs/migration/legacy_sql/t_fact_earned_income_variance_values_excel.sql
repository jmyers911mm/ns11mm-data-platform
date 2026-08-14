-- TRANSFORMATION: t_fact_earned_income_variance_values_excel
-- DESC: 

-- EXCEL OUT: /opt/pentaho/ops_reports/Earned Income Variance Report tmpl=/opt/pentaho/ops_reports/template.xlsx


-- ===== STEP: Table input [TableInput] conn=911DW =====
select date_format(key_date, '%m/%d/%Y') as key_date, actual_tickets, forecasted_tickets, ticket_difference, actual_revenue, forecasted_revenue, revenue_difference, guided_tours, forecasted_guided_tours, guided_tour_diff,
guided_tour_revenue, forecasted_guided_tour_revenue, guided_tour_rev_diff, citypass_tickets, forecasted_citypass_tickets, citypass_tickets_diff,
citypass_revenue, forecasted_citypass_revenue, citypass_revenue_diff
from 
earned_income_report_analysis

order by year(key_date), key_date