-- TRANSFORMATION: t_fact_attendance_all_facilities
-- DESC: 

-- WRITES: 911DW:.fact_attendance_all_facilities (InsertUpdate)


-- ===== STEP: Table input [TableInput] conn=911DW =====
select key_date,facility_code, sum(attendance) as attendance
 from
(SELECT key_date, v.key_facility as facility_code, SUM(v.passes_scanned) as attendance
FROM 911dw.memorial_attendance v, 911dw.dim_date d
WHERE v.key_date = d.date_key
and v.key_facility in (2000)
AND d.date_value >= '20140515'
group by key_date
union
SELECT key_date,  v.key_facility as facility_code,  SUM(v.passes_scanned) as attendance 
FROM 911dw.fact_visitors v, 911dw.dim_date d
WHERE v.key_date = d.date_key
and v.key_facility in ( 1006,3000)
AND d.date_value  >= '20140515'
group by key_date
union
SELECT key_date, v.key_facility as facility_code, SUM(v.num_entry) as attendance
  FROM 911dw.fact_visitors v, 911dw.dim_date d, 911dw.dim_facility f
  WHERE v.key_date = d.date_key
  AND v.key_facility = f.key_facility
  AND f.key_facility = 1007
  AND d.date_value >= '20140515'
group by key_date
union
SELECT key_date, v.key_facility as facility_code, SUM(v.num_exit) as attendance
  FROM 911dw.fact_visitors v, 911dw.dim_date d, 911dw.dim_facility f
  WHERE v.key_date = d.date_key
  AND v.key_facility = f.key_facility
  AND f.key_facility = 1001
  AND d.date_value >= '20140515'
group by key_date
union
select key_date, 1020 as facility_code, sum(mem_attend)-sum(mus_attend) as attendance
from 
(select key_date, sum(passes_scanned) as mem_attend, 0 as mus_attend
from memorial_attendance  v, 911dw.dim_date d
WHERE v.key_date = d.date_key
and v.key_facility in (2000)
AND d.date_value >= '20140515'
group by key_date 
union
select key_date,0 as mem_attend, sum(passes_scanned) as mus_attend
FROM 911dw.fact_visitors v, 911dw.dim_date d
WHERE v.key_date = d.date_key
and v.key_facility in ( 1006,3000)
AND d.date_value  >= '20140515'
group by key_date) as B
group by key_date ) as A
where key_date < ?
group by key_date, facility_code