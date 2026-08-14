-- TRANSFORMATION: t_fact_museum_tickets_issued_fordate_new
-- DESC: 

-- WRITES: 911DW:.fact_museum_tickets_issued_fordate_new (InsertUpdate)
-- LOOKUP: 911DW:.dim_galaxy_items


-- ===== STEP: Museum Issued Tickets [TableInput] conn=Gateway =====
--ORIG 47 SEC V 1 SEC NEW

DECLARE @TOTAL_EVENTS TABLE
(
	EventID INT,
	StartDateTime DATETIME
)
INSERT @TOTAL_EVENTS
SELECT EventID, [StartDateTime]
FROM [dbo].[RMEvents] (NOLOCK)
WHERE StartDateTime >= DATEADD(dd,DATEDIFF(dd,0,GETDATE()-1),0)
    AND StartDateTime < DATEADD(dd,DATEDIFF(dd,0,GETDATE()+0),0)
	AND EventTypeID <> 56 


SELECT
	CONVERT(VARCHAR(12),RMEvents.StartDateTime,112) AS key_date,
	JNLTickets.OrderNo,
	JnlTickets.VisualID,
	ISNULL(vA.rItmMatrixCode,'') 'AccountIDNo',
	Items.PLU,
	Items.itemfilter, 
	JNLTickets.JnlDetailID,
	JnlTickets.CustomerID,
	SUM(Jnldetails.Qty) as Quantity,
	SUM(JNLdetails.Amount) as Amount,
	CASE 
		WHEN JNLTickets.DisbursementID = 0 AND ISNULL(vA.rItmMatrixCode,'') LIKE 'GAD%' THEN 1
		WHEN JNLTickets.DisbursementID <> 0 AND (ISNULL(vA.rItmMatrixCode,'') LIKE 'TOU%' OR ISNULL(vA.rItmMatrixCode,'') LIKE 'MGT%') AND (ISNULL(DisbursementDetails.Name,'GEN ADM') = 'GEN ADM') AND ISNULL(vA.rItmMatrixCode,'') <> '%XGA'  THEN 1 
		ELSE 0 
	END GeneralAdmissionFlag
FROM dbo.JnlDetails (NOLOCK) LEFT OUTER JOIN dbo.JnlTickets (NOLOCK) ON JnlDetails.AuxTableID = JnlTickets.JnlDetailID AND JnlDetails.JnlcodeID = 101
                             INNER JOIN @TOTAL_EVENTS RMEvents ON  RMEvents.EventID= JnlTickets.EventNo 
							 LEFT OUTER JOIN dbo.Items (NOLOCK) ON   JnlTickets.PLU = Items.PLU
							 LEFT OUTER JOIN report.vAttribute vA (NOLOCK) ON   Items.AttributeValueGroupID = vA.avgID
							 LEFT OUTER JOIN dbo.COA (NOLOCK) ON  jnldetails.AccountID = coa.AccountID
							 LEFT OUTER JOIN dbo.DisbursementDetails (NOLOCK) ON (jnltickets.DisbursementID = DisbursementDetails.DisbursementID) and coa.GLCode = 101 and coa.CompanyID = DisbursementDetails.Company and coa.Category = disbursementdetails.Category and coa.subcat = DisbursementDetails.SubCategory                                
WHERE                      
	 Items.PLU <> 'EXTEVENTAD001'
AND (ISNULL(vA.rItmMatrixCode,'') LIKE '%GAD%' OR ISNULL(vA.rItmMatrixCode,'') LIKE '%TOU%')
AND ((vA.rItmDefaultCustomerID NOT IN (20056, 23361)) OR (vA.rItmDefaultCustomerID IS NULL))
    
GROUP BY
	CONVERT(VARCHAR(12),RMEvents.StartDateTime,112),
	JNLTickets.OrderNo,
	JnlTickets.VisualID,
	ISNULL(vA.rItmMatrixCode,''),
	Items.PLU,
	Items.itemfilter, 
	JNLTickets.JnlDetailID,
	JnlTickets.CustomerID,
    CASE 
		WHEN JNLTickets.DisbursementID = 0 AND ISNULL(vA.rItmMatrixCode,'') LIKE 'GAD%' THEN 1
		WHEN JNLTickets.DisbursementID <> 0 AND (ISNULL(vA.rItmMatrixCode,'') LIKE 'TOU%' OR ISNULL(vA.rItmMatrixCode,'') LIKE 'MGT%') AND (ISNULL(DisbursementDetails.Name,'GEN ADM') = 'GEN ADM') AND ISNULL(vA.rItmMatrixCode,'') <> '%XGA'  THEN 1 
    ELSE 0 END