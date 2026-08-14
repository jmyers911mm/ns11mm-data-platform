-- TRANSFORMATION: t_fact_museum_ticketing_donations_unissued
-- DESC: 

-- WRITES: 911DW:.fact_museum_ticketing_donations_unissued (TableOutput)
-- LOOKUP: 911DW:.dim_galaxy_items


-- ===== STEP: Museum Ticketing Donations - Unissued [TableInput] conn=Gateway =====
SELECT CONVERT(varchar(12),o.opendate,112) TransDate, 

		i.PLU,
		--i.descr,
		ISNULL(vA.rItmMatrixCode,'') 'AccountIDNo',
		SUM(d.Quantity - d.IssuedQuantity) QtyUnissued,
		SUM((d.Amount)*(d.quantity-d.issuedquantity)) AmtUnissued
  FROM [orders] o WITH (NOLOCK)
  INNER JOIN [orderlines] d WITH (NOLOCK) ON o.orderid = d.orderid
    INNER JOIN [items] i WITH (NOLOCK) ON d.plu = i.plu
	left outer join report.vAttribute vA (nolock) on  i.AttributeValueGroupID = vA.avgID
  WHERE (ISNULL(vA.rItmMatrixCode,'') like '%MUS%' and ISNULL(vA.rItmMatrixCode,'') like '%DON%')
  AND CONVERT(varchar(12),o.opendate,112) >= '20140326'
  AND (d.Quantity - d.IssuedQuantity) > 0
GROUP BY
CONVERT(varchar(12),o.opendate,112) , 
		i.PLU,
		--i.descr,
		ISNULL(vA.rItmMatrixCode,'')
order by 
CONVERT(varchar(12),o.opendate,112)