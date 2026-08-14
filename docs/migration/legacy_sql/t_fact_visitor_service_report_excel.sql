-- TRANSFORMATION: t_fact_visitor_service_report_excel
-- DESC: 

-- EXCEL OUT: /opt/pentaho/ops_reports/Weekly Revenue Report tmpl=/opt/pentaho/ops_reports/visitor_services_template.xlsx


-- ===== STEP: Table input [TableInput] conn=911DW =====
select
  v.day_name
, date_format(key_date, '%m/%d/%Y') as key_date
, v.mus_attendance
, v.ag_rental
, v.ag_rev
, v.ag_capture_rate
, v.headphone_rental
, v.headphone_rev
, v.headphone_capture_rate,
v.coatcheck_donations,
v.kiosk_donations,
v.infodesk_tours
 from visitor_services_revenue_report v, dim_date d
where v.key_date= d.date_key 
and d.date_value >= '20150101'
and d.date_value < ?