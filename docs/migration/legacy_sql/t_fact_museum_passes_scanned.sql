-- TRANSFORMATION: t_fact_museum_passes_scanned
-- DESC: Museum Passes Scanned

-- WRITES: 911DW:.fact_visitors (InsertUpdate)


-- ===== STEP: Gateway - Usage [TableInput] conn=Gateway =====
select key_date, sum(ps) as ps, ACP, key_facility
from(
Select CONVERT(VARCHAR(8), UseTime, 112) AS key_date,  sum(Qty) as ps,ACP,
case when  Facility.FacilityID=7  then '1006' 
when Facility.FacilityID=12 then '5000' 
else '0' end key_facility
from dbo.Usage inner join ACPs on Usage.ACP=ACPs.AcpId 
inner join Facility on ACps.FacilityID= Facility.IDNo 
where Usage.Status =0 and Usage.Code=0 and  CONVERT(VARCHAR(8), UseTime, 112) >= '20210716'
and Facility.FacilityID <> 13
group by CONVERT(VARCHAR(8), UseTime, 112), ACP, Facility.FacilityID

union
Select CONVERT(VARCHAR(8), UseTime, 112) AS key_date,  -sum(Qty) as ps,ACP,
case when  Facility.FacilityID=7  then '1006' 
when Facility.FacilityID=12 then '5000' 
else '0' end key_facility
from dbo.Usage inner join ACPs on Usage.ACP=ACPs.AcpId 
inner join Facility on ACps.FacilityID= Facility.IDNo 
where Usage.Status =0 and Usage.Code=11 and  CONVERT(VARCHAR(8), UseTime, 112) >= '20210716'
and Facility.FacilityID <> 13
group by CONVERT(VARCHAR(8), UseTime, 112), ACP, Facility.FacilityID
)
as A
group by key_date, ACP, key_facility
order by key_date, ACP