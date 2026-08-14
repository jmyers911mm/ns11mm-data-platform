-- TRANSFORMATION: t_fact_museum_tickets_unissued_fordate_new
-- DESC: 

-- WRITES: 911DW:.fact_museum_tickets_unissued_fordate_new (InsertUpdate)
-- LOOKUP: 911DW:.dim_galaxy_items


-- ===== STEP: Museum Unissued Tickets [TableInput] conn=Gateway =====
SELECT 
      OrderLines.OrderID,
      orderlines.orderlineid,
      CONVERT(VARCHAR(12), RMEvents.StartDateTime,112) as key_date,
            items.PLU,
      ISNULL(vA.rItmMatrixCode,'') 'AccountIDNo',
items.itemfilter,
      CASE WHEN ISNULL(vA.rItmMatrixCode,'') LIKE '%TOU%'  AND OrderLines.DisbursementID <> 0 AND (ISNULL(DisbursementDetails.Name,'GEN ADM') = 'GEN ADM') AND SUBSTRING(ISNULL(vA.rItmMatrixCode,''),17,3) <> 'XGA'  THEN 1 
WHEN ISNULL(vA.rItmMatrixCode,'') LIKE '%GAD%' THEN 1
         ELSE 0 END GeneralAdmissionFlag,
            ISNULL(orderlines.quantity,0) - ISNULL(Orderlines.IssuedQuantity,0) QtyUnissued,
            CASE WHEN ISNULL(orderlines.DisbursementID,0) <> 0 AND DisbursementDetailS.Basis <> 'R' AND DisbursementDetails.Basis = '$'  THEN ((ISNULL(orderlines.quantity,0) - ISNULL(Orderlines.IssuedQuantity,0))*DisbursementDetails.Price)
            WHEN  ISNULL(orderlines.DisbursementID,0) <> 0 AND DisbursementDetails.Basis <> 'R' AND DisbursementDetails.Basis = '%' THEN (((ISNULL(orderlines.Amount,0)-ISNULL(orderlines.DiscountAmount,0))*(ISNULL(orderlines.quantity,0) - ISNULL(Orderlines.IssuedQuantity,0)))/(100/DisbursementDetails.Price))
            WHEN  ISNULL(orderlines.DisbursementID,0) <> 0 THEN  ((ISNULL(orderlines.Amount,0)-ISNULL(orderlines.DiscountAmount,0))*(ISNULL(orderlines.quantity,0) - ISNULL(Orderlines.IssuedQuantity,0)))-((ISNULL(orderlines.quantity,0) - ISNULL(Orderlines.IssuedQuantity,0))*(SELECT SUM(Price) FROM DisbursementDetails  d2 WHERE d2.DisbursementID = DisbursementDetails.DisbursementID))
            ELSE (ISNULL(orderlines.Amount,0)-ISNULL(orderlines.DiscountAmount,0))*(ISNULL(orderlines.quantity,1)-ISNULL(orderlines.issuedquantity,0))
                  END AmtUnissued
FROM [OrderLines] WITH (NOLOCK)
INNER JOIN [Orders] WITH (NOLOCK) ON OrderLines.OrderID = Orders.OrderID
LEFT OUTER JOIN [Items] WITH (NOLOCK) ON OrderLines.PLU = Items.PLU
left outer join report.vAttribute vA (nolock) on  Items.AttributeValueGroupID = vA.avgID
LEFT OUTER JOIN [RMEvents] WITH (NOLOCK) ON OrderLines.EventID = RMEvents.EventID
LEFT OUTER JOIN [DisbursementDetails] WITH (NOLOCK) ON OrderLines.DisbursementID = DisbursementDetails.DisbursementID
WHERE 
Orderlines.IssuedQuantity < Orderlines.Quantity
AND
(ISNULL(vA.rItmMatrixCode,'') LIKE '%TOU%' or ISNULL(vA.rItmMatrixCode,'') like '%GAD%')
and (ISNULL(vA.rItmMatrixCode,'') not like '%CPA%') and (ISNULL(vA.rItmMatrixCode,'') not like '%CPB%') and (ISNULL(vA.rItmMatrixCode,'') not like '%CPC%')

and CONVERT(varchar(12),RMEvents.startdatetime,112) = dateadd(d,-1,?)

UNION ALL
SELECT 
      OrderLines.OrderID,
      orderlines.orderlineid,
      CONVERT(VARCHAR(12), RMEvents.StartDateTime,112) as key_date,
            items.PLU,
     ISNULL(vA.rItmMatrixCode,'') 'AccountIDNo',
items.itemfilter,
      1 GeneralAdmissionFlag,
            ISNULL(orderlines.quantity,0) - ISNULL(Orderlines.IssuedQuantity,0) QtyUnissued,
            0 AmtUnissued
FROM [OrderLines] WITH (NOLOCK)
INNER JOIN [Orders] WITH (NOLOCK) ON OrderLines.OrderID = Orders.OrderID
LEFT OUTER JOIN [Items] WITH (NOLOCK) ON OrderLines.PLU = Items.PLU
left outer join report.vAttribute vA (nolock) on  Items.AttributeValueGroupID = vA.avgID
LEFT OUTER JOIN [RMEvents] WITH (NOLOCK) ON OrderLines.EventID = RMEvents.EventID
LEFT OUTER JOIN [DisbursementDetails] WITH (NOLOCK) ON OrderLines.DisbursementID = DisbursementDetails.DisbursementID
WHERE 
Orderlines.IssuedQuantity < Orderlines.Quantity
  AND
  (ISNULL(vA.rItmMatrixCode,'') LIKE '%TOU%')
  AND
  NOT (ISNULL(vA.rItmMatrixCode,'') LIKE '%XGA%')
  AND
 ISNULL(Orderlines.DisbursementID,0) = 0

and CONVERT(varchar(12),RMEvents.startdatetime,112) = dateadd(d,-1,?)
  
order by CONVERT(varchar(12),RMEvents.startdatetime,112)