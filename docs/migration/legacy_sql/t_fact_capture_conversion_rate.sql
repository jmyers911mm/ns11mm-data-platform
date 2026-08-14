-- TRANSFORMATION: t_fact_capture_conversion_rate
-- DESC: 

-- WRITES: 911DW:.fact_conversion_rate (InsertUpdate)
-- WRITES: 911DW:.fact_capture_rate (InsertUpdate)


-- ===== STEP: Table input [TableInput] conn=911DW =====
select date_key, key_facility, sum(visitors) as visitors, sum(customers) as customers, (sum(customers)/sum(visitors))*100 as conversion_rate
from(select date_key,'1003' as key_facility,SUM(v.num_entry) as visitors, 0 as customers
  FROM 911dw.fact_visitors v, 911dw.dim_date d, 911dw.dim_facility f
  WHERE v.key_date = d.date_key
  AND v.key_facility = f.key_facility
  AND f.key_facility = 1007
  AND d.date_value >= '20140515'
group by date_key
union
SELECT date_key,'1003' as key_facility,0 as visitors,SUM(nt.Num_Tickets) as customers
FROM 911dw.fact_num_tickets nt, 911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = nt.key_facility
AND nt.key_date = d.date_key
AND f.key_facility = 1003
AND d.date_value >= '20140515'
group by date_key
UNION
select date_key,'1001' as key_facility,SUM(v.num_exit) as visitors, 0 as customers
  FROM 911dw.fact_visitors v, 911dw.dim_date d, 911dw.dim_facility f
  WHERE v.key_date = d.date_key
  AND v.key_facility = f.key_facility
  AND f.key_facility = 1001
  AND d.date_value >= '20140515'
group by date_key
union
SELECT date_key,'1001' as key_facility,0 as visitors,SUM(nt.Num_Tickets) as customers
FROM 911dw.fact_num_tickets nt, 911dw.dim_facility f, 911dw.dim_date d
WHERE f.key_facility = nt.key_facility
AND nt.key_date = d.date_key
AND f.key_facility = 1001
AND d.date_value >= '20140515'
group by date_key

 )A
where date_key < ?
group by date_key, key_facility
order by date_key, key_facility

-- ===== STEP: Table input 2 [TableInput] conn=911DW =====
select date_key, facility_name, sum(visitors) as visitors, sum(attendance) as attendance, (sum(visitors)/sum(attendance))*100 as capture_rate
from(select date_key,'Museum Store' as facility_name,SUM(v.num_entry) as visitors, 0 as attendance
  FROM 911dw.fact_visitors v, 911dw.dim_date d, 911dw.dim_facility f
  WHERE v.key_date = d.date_key
  AND v.key_facility = f.key_facility
  AND f.key_facility = 1007
  AND d.date_value >= '20140514'
group by date_key
union
SELECT date_key, 'Museum Store' as facility_name,0 as visitors,SUM(v.passes_scanned) as attendance
FROM 911dw.fact_visitors v, 911dw.dim_date d
WHERE v.key_date = d.date_key
and v.key_facility in ( 1006,3000)
AND d.date_value >= '20140514'
group by date_key
 )A

where date_key < ?
group by date_key
order by date_key