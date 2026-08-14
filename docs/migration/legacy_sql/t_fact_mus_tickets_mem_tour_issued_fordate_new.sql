-- TRANSFORMATION: t_fact_mus_tickets_mem_tour_issued_fordate_new
-- DESC: 

-- WRITES: 911DW:.fact_museum_tickets_issued_fordate_new (InsertUpdate)
-- LOOKUP: 911DW:.dim_galaxy_items


-- ===== STEP: Museum Admission and Memorial Tour Issued Tickets [TableInput] conn=Gateway =====
select
CONVERT(VARCHAR(12),RMEvents.StartDateTime,112) as key_date,
JNLTickets.OrderNo,
JnlTickets.VisualID,
ISNULL(vA.rItmMatrixCode,'') 'AccountIDNo', 
Items.PLU,
Items.itemfilter, 
JNLTickets.JnlDetailID,
JNLTickets.CustomerID,
SUM(Jnldetails.Qty) as Quantity,
SUM(JNLdetails.Amount) as Amount,
CASE WHEN JNLTickets.DisbursementID = 0 AND ISNULL(vA.rItmMatrixCode,'') LIKE 'GAD%' THEN 1
 WHEN JNLTickets.DisbursementID <> 0 AND (ISNULL(vA.rItmMatrixCode,'') LIKE 'TOU%' OR ISNULL(vA.rItmMatrixCode,'') LIKE 'MGT%') AND (ISNULL(DisbursementDetails.Name,'GEN ADM') = 'GEN ADM') AND ISNULL(vA.rItmMatrixCode,'') <> '%XGA'  THEN 1 
  ELSE 0 END GeneralAdmissionFlag
	   
FROM      dbo.JnlDetails (nolock)
                      Left outer join dbo.JnlTickets (nolock) on        JnlDetails.AuxTableID = JnlTickets.JnlDetailID and JnlDetails.JnlcodeID = 101
                     inner join dbo.RMEvents (nolock) on RMEvents.EventID= JnlTickets.EventNo 
                     -- Left outer join dbo.JnlItems (nolock) on        JnlDetails.AuxTableID = JnlItems.JnlItemID and JnlDetails.JnlcodeID IN (102,103,104)
                      left outer join dbo.Items (nolock) on  JnlTickets.PLU = Items.PLU
					  left outer join report.vAttribute vA (nolock) on  Items.AttributeValueGroupID = vA.avgID
                      left outer join dbo.COA (nolock) on jnldetails.AccountID = coa.AccountID
                      left outer join dbo.DisbursementDetails (nolock) ON (jnltickets.DisbursementID = DisbursementDetails.DisbursementID) and coa.GLCode = 101 and coa.CompanyID = DisbursementDetails.Company and coa.Category = disbursementdetails.Category and coa.subcat = DisbursementDetails.SubCategory
                                   
where                      
                      RMEvents.EventTypeID <> 56 
					
				    and CONVERT(VARCHAR(12),RMEvents.StartDateTime,112) = dateadd(d,-1,?)
					and Items.PLU not in ('EXTEVENTAD001')
					
                      and (ISNULL(vA.rItmMatrixCode,'') like '%MGT%' or ISNULL(vA.rItmMatrixCode,'') like '%XXX%')
					and (vA.rItmDefaultCustomerID not in (20056, 23361) or vA.rItmDefaultCustomerID is null)
    
group by
CONVERT(VARCHAR(12),RMEvents.StartDateTime,112) ,
JNLTickets.OrderNo,
JnlTickets.VisualID,
ISNULL(vA.rItmMatrixCode,''), 
Items.PLU,
Items.itemfilter, 
JNLTickets.JnlDetailID,
JNLTickets.CustomerID,
CASE WHEN JNLTickets.DisbursementID = 0 AND ISNULL(vA.rItmMatrixCode,'') LIKE 'GAD%' THEN 1
	   WHEN JNLTickets.DisbursementID <> 0 AND (ISNULL(vA.rItmMatrixCode,'') LIKE 'TOU%' OR ISNULL(vA.rItmMatrixCode,'') LIKE 'MGT%') AND (ISNULL(DisbursementDetails.Name,'GEN ADM') = 'GEN ADM') AND ISNULL(vA.rItmMatrixCode,'') <> '%XGA'  THEN 1 
	   ELSE 0 END
order by 
CONVERT(VARCHAR(12),RMEvents.StartDateTime,112)