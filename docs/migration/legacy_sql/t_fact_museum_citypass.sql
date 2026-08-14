-- TRANSFORMATION: t_fact_museum_citypass
-- DESC: 

-- WRITES: 911DW:.fact_museum_citypass (InsertUpdate)
-- LOOKUP: 911DW:.dim_citypass_revenue
-- LOOKUP: 911DW:.dim_galaxy_items


-- ===== STEP: Museum Issued Tickets [TableInput] conn=Gateway =====
select  
CONVERT(VARCHAR(12),RMEvents.StartDateTime,112) as key_date,
JNLTickets.OrderNo,
JnlTickets.VisualID,
ISNULL(vA.rItmMatrixCode,'') 'AccountIDNo', 
case when Items.PLU like '%MUSGADADCP001%' then 'Adult' 
when Items.PLU like '%MUSGADYSCP001%' then 'Youth' 
when Items.PLU like '%MUSGADADCP003%' then 'Adult' 
when Items.PLU like '%MUSGADYSCP003%' then 'Youth' 
when Items.PLU in ('CPBOOKAD007') then 'C3 Adult'
when Items.PLU in ('CPBOOKYS007') then 'C3 Youth'
else 'None' end as ItemsName,
Items.PLU,
Items.itemfilter, 
JNLTickets.JnlDetailID,
SUM(Jnldetails.Qty) as Quantity,
SUM(JNLdetails.Amount) as Amount
	   
FROM      dbo.JnlDetails (nolock)
                      Left outer join dbo.JnlTickets (nolock) on        JnlDetails.AuxTableID = JnlTickets.JnlDetailID and JnlDetails.JnlcodeID = 101
                      Left outer join dbo.RMEvents (nolock) on RMEvents.EventID= JnlTickets.EventNo 
                      Left outer join dbo.JnlItems (nolock) on        JnlDetails.AuxTableID = JnlItems.JnlItemID and JnlDetails.JnlcodeID IN (102,103,104)
                      left outer join dbo.Items (nolock) on JnlItems.PLU = Items.PLU or JnlTickets.PLU = Items.PLU
					  left outer join report.vAttribute vA (nolock) on  Items.AttributeValueGroupID = vA.avgID
                      left outer join dbo.COA (nolock) on jnldetails.AccountID = coa.AccountID
                      left outer join dbo.DisbursementDetails (nolock) ON (jnltickets.DisbursementID = DisbursementDetails.DisbursementID) and coa.GLCode = 101 and coa.CompanyID = DisbursementDetails.Company and coa.Category = disbursementdetails.Category and coa.subcat = DisbursementDetails.SubCategory
                                   
where                      
                      RMEvents.EventTypeID <> 56 
						--and  CONVERT(VARCHAR(12),RMEvents.StartDateTime,112) >= '20151030'
						and CONVERT(VARCHAR(12),RMEvents.StartDateTime,112) >= dateadd(d,-150,?)
                    	and ((ISNULL(vA.rItmMatrixCode,'') like '%CPA%' or ISNULL(vA.rItmMatrixCode,'') like '%CPB%' ) or Items.PLU in ('CPBOOKAD007','CPBOOKYS007'))
						and Items.PLU not in ('CPBOOKAD008''CPBOOKYS008','CPBOOKAD005','CPBOOKYS005','CPBOOKYS009','CPBOOKAD009', 'CPBOOKAD010', 'CPBOOKYS010')
    
group by
CONVERT(VARCHAR(12),RMEvents.StartDateTime,112) ,
JNLTickets.OrderNo,
JnlTickets.VisualID,
ISNULL(vA.rItmMatrixCode,'') , 
Items.PLU,
Items.itemfilter, 
JNLTickets.JnlDetailID
order by 
CONVERT(VARCHAR(12),RMEvents.StartDateTime,112)