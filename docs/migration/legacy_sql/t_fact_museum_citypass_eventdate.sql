-- TRANSFORMATION: t_fact_museum_citypass_eventdate
-- DESC: 

-- WRITES: 911DW:.fact_museum_citypass_scanchange (InsertUpdate)
-- LOOKUP: 911DW:.dim_citypass_revenue
-- LOOKUP: 911DW:.dim_galaxy_items


-- ===== STEP: CityPASS Tickets - Event date [TableInput] conn=Gateway =====
SELECT
  CONVERT(varchar(12), rmE.startDateTime, 112) AS 'key_date',
	isnull(jnlT.orderNo,0) AS 'OrderNo',
  jnlT.visualID AS 'VisualID',
  ISNULL(vA.rItmMatrixCode,'') 'AccountIDNo',
  CASE
    WHEN  vA.rItmDefaultCustomerID = 20056 and vA.rItmPricePointID = 83 THEN 'Adult'
    WHEN  vA.rItmDefaultCustomerID = 23361 and vA.rItmPricePointID = 83 THEN 'C3 Adult'
    WHEN vA.rItmDefaultCustomerID = 20056 and vA.rItmPricePointID = 86 THEN 'Youth'
    WHEN vA.rItmDefaultCustomerID = 23361 and vA.rItmPricePointID = 86  THEN 'C3 Youth'
    ELSE 'None'
  END AS ItemsName,
  jnlT.plu 'plu',
  i.itemFilter 'itemFilter',
  '0' 'jnlDetailID',
  SUM(jnlT.qty) 'quantity',
  0.00 AS 'amount'
FROM
	rmEvents	rmE
	JOIN	jnlTickets	jnlT	ON	rmE.eventID	=	jnlT.eventNo
JOIN items i   ON jnlT.plu = i.plu
left outer Join Report.vAttribute vA on i.AttributeValueGroupID = vA.avgID and vA.rItmDefaultCustomerID in ( 20056, 23361)
WHERE 
 vA.rItmDefaultCustomerID in ( 20056, 23361)
and vA.rItmProductID = 77
AND CONVERT(varchar(8), rmE.startDateTime, 112) >= dateadd(d,-297,?)
GROUP BY
CONVERT(varchar(12), rmE.startDateTime, 112),
ISNULL(jnlT.orderNo,0),
  jnlT.visualID,
  ISNULL(vA.rItmMatrixCode,''),
  CASE
    WHEN  vA.rItmDefaultCustomerID = 20056 and vA.rItmPricePointID = 83 THEN 'Adult'
    WHEN  vA.rItmDefaultCustomerID = 23361 and vA.rItmPricePointID = 83 THEN 'C3 Adult'
    WHEN vA.rItmDefaultCustomerID = 20056 and vA.rItmPricePointID = 86 THEN 'Youth'
    WHEN vA.rItmDefaultCustomerID = 23361 and vA.rItmPricePointID = 86  THEN 'C3 Youth'
    ELSE 'None'
  END,
  jnlT.plu,
  i.itemFilter