-- TRANSFORMATION: t_fact_museum_membership_desk
-- DESC: 

-- WRITES: 911DW:.fact_museum_membership_desk (InsertUpdate)
-- LOOKUP: 911DW:.dim_galaxy_items


-- ===== STEP: Membership Desk [TableInput] conn=Gateway =====
SELECT     convert(varchar(10),JnlHeaders.TranDate,112) as key_date , 
JNLItems.PLU,
ISNULL(vA.rItmMatrixCode,'') 'AccountIDNo',
Items.Cost,
Items.Price, 
sum(JNLItems.Tax) as Tax,
sum(JnlDetails.Qty) as Qty, 
sum(JnlDetails.Amount) as Amount
FROM         JnlHeaders 
			INNER JOIN JnlDetails ON JnlHeaders.JnlTranID = JnlDetails.JnlTranID and JnlDetails.JnlCodeID  = 102
			left outer join JnlItems (nolock) on JnlDetails.AuxTableID=JnlItems.JnlItemID
 			INNER JOIN  Items ON JnlItems.PLU = Items.PLU
			left outer join report.vAttribute vA (nolock) on  Items.AttributeValueGroupID = vA.avgID
WHERE   (Items.Kind IN ('8'))
and (JnlItems.PLU like '%MBR%' )
and  convert(varchar(10),JnlHeaders.TranDate,112) >= dateadd(d,-11,?)
group by 
convert(varchar(10),JnlHeaders.TranDate,112),
 JNLItems.PLU,
 ISNULL(vA.rItmMatrixCode,''),
 Items.Price,
 Items.Cost

order by key_date