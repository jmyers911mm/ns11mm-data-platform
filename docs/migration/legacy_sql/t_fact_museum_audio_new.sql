-- TRANSFORMATION: t_fact_museum_audio_new
-- DESC: 

-- WRITES: 911DW:.fact_museum_audio_new (InsertUpdate)
-- LOOKUP: 911DW:.dim_galaxy_items


-- ===== STEP: ti2: Audio Guides from JnlTickets [TableInput] conn=Gateway =====
SELECT     convert(varchar(8),JnlHeaders.TranDate,112) as key_date , jnlTickets.PLU,ISNULL(vA.rItmMatrixCode,'') 'AccountIDNo',Items.Cost,
Items.Price, cast(sum(jnlTickets.Tax) as decimal(19,4)) as Tax,sum(JnlDetails.Qty) as Qty, 
sum(JnlDetails.Amount) as Amount
FROM         JnlHeaders INNER JOIN
                      JnlDetails ON JnlHeaders.JnlTranID = JnlDetails.JnlTranID and JnlDetails.JnlCodeID=101
                     left outer join jnlTickets (nolock) on JnlDetails.AuxTableID=jnlTickets.jnlDetailID
             INNER JOIN  Items ON jnlTickets.PLU = Items.PLU
			 left outer join report.vAttribute vA (nolock) on  Items.AttributeValueGroupID = vA.avgID
WHERE   
(Items.Kind IN (1,5)) and
(jnlTickets.PLU in ('AUDIO0004','AUDIO0005','AUDIO0006','AUDIO0007','AUDIO0008','AUDIO0009','AUDIO0021') )
and  convert(varchar(10),JnlHeaders.TranDate,112) >= '20140515'
group by 
convert(varchar(8),JnlHeaders.TranDate,112),
jnlTickets.PLU,
ISNULL(vA.rItmMatrixCode,''),
Items.Price,
Items.Cost

-- ===== STEP: ti: Audio Guides from JnlItems [TableInput] conn=Gateway =====
SELECT     convert(varchar(8),JnlHeaders.TranDate,112) as key_date , JNLItems.PLU,ISNULL(vA.rItmMatrixCode,'') 'AccountIDNo',Items.Cost,
Items.Price, cast(sum(JNLItems.Tax) as decimal(19,4)) as Tax,sum(JnlDetails.Qty) as Qty, 
sum(JnlDetails.Amount) as Amount
FROM         JnlHeaders INNER JOIN
                      JnlDetails ON JnlHeaders.JnlTranID = JnlDetails.JnlTranID and JnlDetails.JnlCodeID=102
                     left outer join JnlItems (nolock) on JnlDetails.AuxTableID=JnlItems.JnlItemID
             INNER JOIN  Items ON JnlItems.PLU = Items.PLU
			left outer join report.vAttribute vA (nolock) on  Items.AttributeValueGroupID = vA.avgID
WHERE   
(Items.Kind IN ('8')) and
(JnlItems.PLU in ('AUDIO1001','AUDIO0001') )
and  convert(varchar(10),JnlHeaders.TranDate,112) >= '20140515'
group by 
convert(varchar(8),JnlHeaders.TranDate,112),
JNLItems.PLU,
ISNULL(vA.rItmMatrixCode,''),
Items.Price,
Items.Cost