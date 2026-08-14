-- TRANSFORMATION: t_fact_visitors_hourly
-- DESC: 

-- WRITES: 911DW:.fact_visitors_hourly (InsertUpdate)


-- ===== STEP: SenSource - Facility [TableInput] conn=SenSource =====
SELECT DATEPART(HOUR,SD.ServerDate) as hourofday,
CONVERT(varchar(12),SD.ServerDate,112) as key_date,
SERVERS.ParentFacility,
  sum(SD.ValueA) as num_entry,
  sum(SD.ValueB) as num_exit
FROM dbo.SensorData SD, dbo.Servers SERVERS
where SD.ServerID=SERVERS.ServerID 
and CONVERT(VARCHAR(8), SD.ServerDate, 112)=?
and SERVERS.ParentFacility in ( 1007)
group by 
DATEPART(HOUR,SD.ServerDate),
CONVERT(varchar(12),SD.ServerDate,112),
SERVERS.ParentFacility
order by  DATEPART(HOUR,SD.ServerDate),
CONVERT(varchar(12),SD.ServerDate,112),
SERVERS.ParentFacility