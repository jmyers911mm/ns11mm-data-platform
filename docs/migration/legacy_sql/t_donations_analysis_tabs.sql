-- TRANSFORMATION: t_donations_analysis_tabs
-- DESC: 

-- EXCEL OUT: /opt/pentaho/ops_reports/Donations Analysis Report tmpl=/opt/pentaho/ops_reports/report_empty.xlsx
-- EXCEL OUT: /opt/pentaho/ops_reports/Donations Analysis Report tmpl=/opt/pentaho/ops_reports/report_empty.xlsx
-- EXCEL OUT: /opt/pentaho/ops_reports/Donations Analysis Report tmpl=/opt/pentaho/ops_reports/report_empty.xlsx
-- EXCEL OUT: /opt/pentaho/ops_reports/Donations Analysis Report tmpl=/opt/pentaho/ops_reports/report_empty.xlsx
-- EXCEL OUT: /opt/pentaho/ops_reports/Donations Analysis Report tmpl=/opt/pentaho/ops_reports/report_empty.xlsx
-- EXCEL OUT: /opt/pentaho/ops_reports/Donations Analysis Report tmpl=/opt/pentaho/ops_reports/report_empty.xlsx
-- EXCEL OUT: /opt/pentaho/ops_reports/Donations Analysis Report tmpl=/opt/pentaho/ops_reports/report_empty.xlsx
-- EXCEL OUT: /opt/pentaho/ops_reports/Donations Analysis Report tmpl=/opt/pentaho/ops_reports/report_empty.xlsx
-- EXCEL OUT: /opt/pentaho/ops_reports/Donations Analysis Report tmpl=/opt/pentaho/ops_reports/report_empty.xlsx
-- EXCEL OUT: /opt/pentaho/ops_reports/Donations Analysis Report tmpl=/opt/pentaho/ops_reports/report_empty.xlsx
-- EXCEL OUT: /opt/pentaho/ops_reports/Donations Analysis Report tmpl=/opt/pentaho/ops_reports/report_empty.xlsx
-- EXCEL OUT: /opt/pentaho/ops_reports/Donations Analysis Report tmpl=/opt/pentaho/ops_reports/report_empty.xlsx
-- EXCEL OUT: /opt/pentaho/ops_reports/Donations Analysis Report tmpl=/opt/pentaho/ops_reports/report_empty.xlsx


-- ===== STEP: Table input [TableInput] conn=911DW =====
SELECT
  date_format(key_date, '%m/%d/%Y') as key_date,
year(key_date) as year
 , month_name
, day_name
, mem_attendance
, mus_attendnace
, ticketing_donations
, mus_store_visitors
, mus_store_don
, ms_don_per_store_visitor
, ms_don_per_mus_visitor
, vesey_visitors
, vesey_donations
, vesey_don_per_vesey_visitor
, retail_cart_don
, vs_cart_don
, total_cart_don
, cart_don_per_mem_only_visitor
, cafe1_donations as cafe_donations
, coatcheck_don
, coatcheck_don_per_mus_visitor
, mus_exit_don
, mus_exit_don_per_mus_visitor
FROM fact_donations_analysis_report
order by year(key_date), key_date