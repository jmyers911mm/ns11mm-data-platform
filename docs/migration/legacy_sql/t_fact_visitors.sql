-- TRANSFORMATION: t_fact_visitors
-- DESC: 

-- WRITES: 911DW:.fact_visitors (InsertUpdate)


-- ===== STEP: SenSource - Facility [TableInput] conn=SenSource =====
SELECT
CONVERT(VARCHAR(8), SD.ServerDate, 112) AS key_date,
SERVERS.ParentFacility,
  sum(SD.ValueA) as num_entry,
  sum(SD.ValueB) as num_exit
FROM dbo.SensorData SD, dbo.Servers SERVERS
where SD.ServerID=SERVERS.ServerID 
--and CONVERT(VARCHAR(8), SD.ServerDate, 112)>='20140515'
and CONVERT(VARCHAR(8), SD.ServerDate, 112)>='20171101'
and SERVERS.ParentFacility in ( 1000,1001,1002,1003,1004,1005,1006,1007,1008,1009)
group by 
CONVERT(VARCHAR(8), ServerDate, 112),SERVERS.ParentFacility
order by CONVERT(VARCHAR(8), ServerDate, 112),SERVERS.ParentFacility