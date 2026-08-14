-- TRANSFORMATION: t_dim_galaxy_ticket_types
-- DESC: 

-- WRITES: 911DW:.dim_galaxy_items (InsertUpdate)


-- ===== STEP: Items [TableInput] conn=Gateway =====
Select 
ItemId, ISNULL(vA.rItmMatrixCode,'') 'AccountIDNo', PLU, ItemFilter, Descr, Cost, Price, EventID, EventType
from Items (nolock)
left outer join report.vAttribute vA (nolock) on  Items.AttributeValueGroupID = vA.avgID