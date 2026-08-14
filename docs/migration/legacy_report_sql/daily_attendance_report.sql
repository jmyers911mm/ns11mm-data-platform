-- REPORT: Daily Attendance Report (daily_attendance_report)

-- ===== [datasources/sql-ds.xml] query: Master =====
SELECT (
SELECT SUM(p.passes)
FROM 911dw.fact_passes_by_hour p, 911dw.dim_date d
WHERE p.key_date = d.date_key
AND d.date_value = ${today})
AS mus_attendance