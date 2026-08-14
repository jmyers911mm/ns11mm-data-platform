-- TRANSFORMATION: t_attendance_values_excel
-- DESC: 

-- EXCEL OUT: /opt/pentaho/ops_reports/Attendance Report tmpl=/opt/pentaho/ops_reports/report_empty.xlsx


-- ===== STEP: Table input [TableInput] conn=911DW =====
select date_format(key_date, '%m/%d/%Y') as key_date, 
mem_attendance,
mus_attendance,
memorial_only,
mus_store,
mus_store_vesey
from fact_attendance_all_locations
order by key_date