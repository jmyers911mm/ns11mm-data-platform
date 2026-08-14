-- TRANSFORMATION: t_visitor_services_tabs_2
-- DESC: 

-- EXCEL OUT: /opt/pentaho/ops_reports/VS Revenue Report tmpl=/opt/pentaho/ops_reports/report_empty.xlsx
-- EXCEL OUT: /opt/pentaho/ops_reports/VS Revenue Report tmpl=/opt/pentaho/ops_reports/report_empty.xlsx
-- EXCEL OUT: /opt/pentaho/ops_reports/VS Revenue Report tmpl=/opt/pentaho/ops_reports/report_empty.xlsx
-- EXCEL OUT: /opt/pentaho/ops_reports/VS Revenue Report tmpl=/opt/pentaho/ops_reports/report_empty.xlsx
-- EXCEL OUT: /opt/pentaho/ops_reports/VS Revenue Report tmpl=/opt/pentaho/ops_reports/report_empty.xlsx
-- EXCEL OUT: /opt/pentaho/ops_reports/VS Revenue Report tmpl=/opt/pentaho/ops_reports/report_empty.xlsx
-- EXCEL OUT: /opt/pentaho/ops_reports/VS Revenue Report tmpl=/opt/pentaho/ops_reports/report_empty.xlsx


-- ===== STEP: Table input [TableInput] conn=911DW =====
SELECT
  key_date
, year(key_date) as year
, month_name
, day_name
, mus_attendance
, ag_rental
, budget_ag_rental
, variance_ag_rental
, ag_rev
, budget_ag_rev
, variance_ag_rev
, ag_cr
, budget_ag_cr
, variance_ag_cr
, headphone_rental
, budget_headphone_rental
, variance_headphone_rental
, headphone_rev
, budget_headphone_rev
, variance_headphone_rev
, headphone_cr
, budget_headphone_cr
, variance_headphone_cr
, coatcheck_don
, budget_coatcheck_don
, variance_coatcheck
, mem_kiosk_don
, info_desk_mus_gt
FROM fact_vs_revenue_report
order by key_date