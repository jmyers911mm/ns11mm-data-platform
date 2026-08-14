-- TRANSFORMATION: t_fact_total_tours_available
-- DESC: 

-- WRITES: 911DW:.fact_total_tours_available (TableOutput)


-- ===== STEP: Table input [TableInput] conn=Gateway =====
select convert(varchar(12), StartDateTime, 112) as key_date, EventTypeID,RMCapacity.ResourceID, SUM(RMCapacity.TotalCapacity) as Capacity from RMEvents, RMCapacity
where RMEvents.EventID = RMCapacity.EventID
and RMEvents.EventTypeID in (93,115,135)
and RMCapacity.CapacityType = 0
and RMEvents.ActiveIndicator <> 1
and RMCapacity.ResourceID in (71,133,203)
group by convert(varchar(12),  StartDateTime, 112), EventTypeID, RMCapacity.ResourceID
order by convert(varchar(12),  StartDateTime, 112)