-- TRANSFORMATION: t_fact_attendance_all_locations
-- DESC: 

-- WRITES: 911DW:.fact_attendance_all_locations (InsertUpdate)


-- ===== STEP: Table input [TableInput] conn=911DW =====
select key_date, sum(memorial_attendance) as 'Memorial Attendance',
 sum(museum_attendance) as 'Museum Attendance', 
sum(memorial_attendance - museum_attendance) as 'Memorial Only',
sum(museum_store) as 'Museum Store',
 sum(museum_store_vesey) as 'Museum Store (at Vesey)'
 from
(SELECT key_date, SUM(v.passes_scanned) as memorial_attendance, 0 as museum_attendance, 0 as museum_store, 0 as museum_store_vesey
FROM 911dw.memorial_attendance v, 911dw.dim_date d
WHERE v.key_date = d.date_key
and v.key_facility in (2000)
AND d.date_value >= '20150101'
group by key_date
union
SELECT key_date,  0 as memorial_attendance, SUM(v.passes_scanned) as museum_attendance , 0 as museum_store, 0 as museum_store_vesey
FROM 911dw.fact_visitors v, 911dw.dim_date d
WHERE v.key_date = d.date_key
and v.key_facility in ( 1006,3000)
AND d.date_value  >= '20150101'
group by key_date
union
SELECT key_date, 0 as memorial_attendance, 0 as museum_attendance, SUM(v.num_entry) as museum_store, 0 as museum_store_vesey
  FROM 911dw.fact_visitors v, 911dw.dim_date d, 911dw.dim_facility f
  WHERE v.key_date = d.date_key
  AND v.key_facility = f.key_facility
  AND f.key_facility = 1007
  AND d.date_value >= '20150101'
group by key_date
union
SELECT key_date, 0 as memorial_attendance, 0 as museum_attendance, 0 as museum_store,SUM(v.num_exit) as museum_store_vesey
  FROM 911dw.fact_visitors v, 911dw.dim_date d, 911dw.dim_facility f
  WHERE v.key_date = d.date_key
  AND v.key_facility = f.key_facility
  AND f.key_facility = 1001
  AND d.date_value >= '20150101'
group by key_date) as A
where key_date < ?
group by key_date