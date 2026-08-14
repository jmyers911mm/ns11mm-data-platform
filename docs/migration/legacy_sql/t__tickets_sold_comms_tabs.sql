-- TRANSFORMATION: t__tickets_sold_comms_tabs
-- DESC: 

-- EXCEL OUT: /opt/pentaho/ops_reports/Museum Attendance Report tmpl=/opt/pentaho/ops_reports/report_empty.xlsx
-- EXCEL OUT: /opt/pentaho/ops_reports/Museum Attendance Report tmpl=/opt/pentaho/ops_reports/report_empty.xlsx
-- EXCEL OUT: /opt/pentaho/ops_reports/Museum Attendance Report tmpl=/opt/pentaho/ops_reports/report_empty.xlsx
-- EXCEL OUT: /opt/pentaho/ops_reports/Museum Attendance Report tmpl=/opt/pentaho/ops_reports/report_empty.xlsx
-- EXCEL OUT: /opt/pentaho/ops_reports/Museum Attendance Report tmpl=/opt/pentaho/ops_reports/report_empty.xlsx
-- EXCEL OUT: /opt/pentaho/ops_reports/Museum Attendance Report tmpl=/opt/pentaho/ops_reports/report_empty.xlsx
-- EXCEL OUT: /opt/pentaho/ops_reports/Museum Attendance Report tmpl=/opt/pentaho/ops_reports/report_empty.xlsx


-- ===== STEP: Table input [TableInput] conn=911DW =====
select monthname(key_date) as month,
dayname(key_date) as theday, 
date_format(key_date, '%m/%d/%Y') as key_date, 
year(key_date) as year,
sum(total_tickets + ifnull(evergreen_tickets,0)) as total_tickets
from 
earned_revenue_report_values
group by key_date
order by year(key_date), key_date