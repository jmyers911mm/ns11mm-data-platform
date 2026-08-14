-- TRANSFORMATION: t_fact_museum_additional_revenue
-- DESC: 

-- WRITES: 911DW:.fact_museum_citypass (InsertUpdate)
-- WRITES: 911DW:.fact_museum_citypass (InsertUpdate)
-- WRITES: 911DW:.fact_museum_nyp_add (InsertUpdate)
-- WRITES: 911DW:.fact_bulk_tickets_add (InsertUpdate)
-- LOOKUP: 911DW:.dim_galaxy_items
-- LOOKUP: 911DW:.dim_galaxy_items
-- LOOKUP: 911DW:.dim_galaxy_items
-- LOOKUP: 911DW:.dim_galaxy_items


-- ===== STEP: Bulk Tickets Additional Revenue [TableInput] conn=Gateway =====
SELECT    
convert(varchar(10),JnlHeaders.FiscalDate,112) as key_date ,
--convert(varchar(10),JnlHeaders.TranDate,112) as transaction_date,
JnlDetails.JnlDetailID,
  Items.PLU,
 ISNULL(vA.rItmMatrixCode,'') 'AccountIDNo',
sum(JnlDetails.Qty) as Qty, sum(JnlDetails.Amount) as Amount
FROM         JnlHeaders INNER JOIN
                      JnlDetails ON JnlHeaders.JnlTranID = JnlDetails.JnlTranID 
						left outer join JnlItems (nolock) on JnlDetails.AuxTableID=JnlItems.JnlItemID 
				INNER JOIN Items ON JnlItems.PLU = Items.PLU
				left outer join report.vAttribute vA (nolock) on  Items.AttributeValueGroupID = vA.avgID
WHERE   (Items.PLU = 'RESLADDREV001' )
and  convert(varchar(10),JnlHeaders.TranDate,112) >= '20170401'
and JNLDetails.Qty <>0
group by 
convert(varchar(10),JnlHeaders.FiscalDate,112),
--convert(varchar(10),JnlHeaders.TranDate,112),
JnlDetails.JnlDetailID,
 Items.PLU,
  ISNULL(vA.rItmMatrixCode,'')
 order by key_date

-- ===== STEP: CityPASS Additional Revenue [TableInput] conn=Gateway =====
SELECT    
convert(varchar(10),JnlHeaders.FiscalDate,112) as key_date ,
--convert(varchar(10),JnlHeaders.TranDate,112) as transaction_date,
JnlDetails.JnlDetailID,
  Items.PLU,
  ISNULL(vA.rItmMatrixCode,'') 'AccountIDNo',
sum(JnlDetails.Qty) as Qty, sum(JnlDetails.Amount) as Amount
FROM         JnlHeaders INNER JOIN
                      JnlDetails ON JnlHeaders.JnlTranID = JnlDetails.JnlTranID 
						left outer join JnlItems (nolock) on JnlDetails.AuxTableID=JnlItems.JnlItemID 
				INNER JOIN Items ON JnlItems.PLU = Items.PLU
				left outer join report.vAttribute vA (nolock) on  Items.AttributeValueGroupID = vA.avgID
WHERE   (Items.PLU like 'CPADDREV001' )
and  convert(varchar(10),JnlHeaders.TranDate,112) >= '20150201'
and JNLDetails.Qty <>0
group by 
convert(varchar(10),JnlHeaders.FiscalDate,112),
--convert(varchar(10),JnlHeaders.TranDate,112),
JnlDetails.JnlDetailID,
 Items.PLU,
 ISNULL(vA.rItmMatrixCode,'')
 order by key_date

-- ===== STEP: CityPASS Additional Revenue 2 [TableInput] conn=Gateway =====
SELECT    
convert(varchar(10),JnlHeaders.FiscalDate,112) as key_date , 
--convert(varchar(10),JnlHeaders.TranDate,112) as transaction_date, 
JnlDetails.JnlDetailID, 
  Items.PLU,
  ISNULL(vA.rItmMatrixCode,'') 'AccountIDNo', 
sum(JnlDetails.Qty) as Qty, sum(JnlDetails.Amount) as Amount 
FROM         JnlHeaders INNER JOIN 
                      JnlDetails ON JnlHeaders.JnlTranID = JnlDetails.JnlTranID 
                      left outer join Jnltickets (nolock) on JnlDetails.AuxTableID=Jnltickets.JnldetailID  
                      INNER JOIN Items ON Jnltickets.PLU = Items.PLU 
					  left outer join report.vAttribute vA (nolock) on  Items.AttributeValueGroupID = vA.avgID
WHERE   ( Items.PLU ='CPADDREV002') 
and  convert(varchar(10),JnlHeaders.TranDate,112) >= '20160531'
and JNLDetails.Qty <>0 
group by 
convert(varchar(10),JnlHeaders.FiscalDate,112), 
--convert(varchar(10),JnlHeaders.TranDate,112), 
JnlDetails.JnlDetailID, 
 Items.PLU, 
 ISNULL(vA.rItmMatrixCode,'')
 order by key_date

-- ===== STEP: New York Pass Additional Revenue [TableInput] conn=Gateway =====
SELECT    
convert(varchar(10),JnlHeaders.FiscalDate,112) as key_date ,
--convert(varchar(10),JnlHeaders.TranDate,112) as transaction_date,
JnlDetails.JnlDetailID,
  Items.PLU,
ISNULL(vA.rItmMatrixCode,'') 'AccountIDNo',
sum(JnlDetails.Qty) as Qty, sum(JnlDetails.Amount) as Amount
FROM         JnlHeaders INNER JOIN
                      JnlDetails ON JnlHeaders.JnlTranID = JnlDetails.JnlTranID 
						left outer join JnlItems (nolock) on JnlDetails.AuxTableID=JnlItems.JnlItemID 
				INNER JOIN Items ON JnlItems.PLU = Items.PLU
				left outer join report.vAttribute vA (nolock) on  Items.AttributeValueGroupID = vA.avgID
WHERE   (ISNULL(vA.rItmMatrixCode,'') like '%GAD-NYA-NYA-OTH-XXX%' )
and  convert(varchar(10),JnlHeaders.TranDate,112) >= '20160601'
and JNLDetails.Qty <>0
group by 
convert(varchar(10),JnlHeaders.FiscalDate,112),
--convert(varchar(10),JnlHeaders.TranDate,112),
JnlDetails.JnlDetailID,
 Items.PLU,
 ISNULL(vA.rItmMatrixCode,'')
 order by key_date