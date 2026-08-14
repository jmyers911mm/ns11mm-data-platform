-- TRANSFORMATION: t_earned_income_variance_tabs_bkp
-- DESC: 

-- EXCEL OUT: /opt/pentaho/ops_reports/Earned Income Variance Report tmpl=/opt/pentaho/ops_reports/report_empty.xlsx
-- EXCEL OUT: /opt/pentaho/ops_reports/Earned Income Variance Report tmpl=/opt/pentaho/ops_reports/report_empty.xlsx
-- EXCEL OUT: /opt/pentaho/ops_reports/Earned Income Variance Report tmpl=/opt/pentaho/ops_reports/report_empty.xlsx
-- EXCEL OUT: /opt/pentaho/ops_reports/Earned Income Variance Report tmpl=/opt/pentaho/ops_reports/report_empty.xlsx
-- EXCEL OUT: /opt/pentaho/ops_reports/Earned Income Variance Report tmpl=/opt/pentaho/ops_reports/report_empty.xlsx


-- ===== STEP: Table input [TableInput] conn=911DW =====
select monthname(key_date) as month,
dayname(key_date) as theday, 
date_format(key_date, '%m/%d/%Y') as key_date, 
year(key_date) as year,
actual_mus_attendance,
forecasted_mus_attendance,
attendance_diff,
 actual_tickets, forecasted_tickets, ticket_difference, actual_revenue, forecasted_revenue, revenue_difference, 
avg_ticket_price,
forecasted_avg_ticket_price,
avg_ticket_price_diff,
service_fees,
forecasted_service_fees,
service_fees_diff,
citypass_tickets, forecasted_citypass_tickets, citypass_tickets_diff,
citypass_revenue, forecasted_citypass_revenue, citypass_revenue_diff,
total_tickets_sold, forecasted_total_tickets_sold, total_tickets_sold_diff,
total_admissions_rev, forecasted_total_admissions_rev, total_admissions_rev_diff,
guided_tours, forecasted_guided_tours, guided_tour_diff,
guided_tour_revenue, forecasted_guided_tour_revenue, guided_tour_rev_diff, 
mem_guided_tours, forecasted_mem_guided_tours, mem_guided_tours_diff,
mem_guided_tour_rev, forecasted_mem_guided_tour_rev, mem_guided_tour_rev_diff,
early_access_tours, forecasted_early_access_tours, early_access_tours_variance, 
early_access_tour_rev, forecasted_early_access_tour_rev, early_access_tour_rev_variance
from 
earned_income_report_analysis

order by year(key_date), key_date