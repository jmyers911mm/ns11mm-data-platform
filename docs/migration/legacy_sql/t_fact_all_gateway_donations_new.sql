-- TRANSFORMATION: t_fact_all_gateway_donations_new
-- DESC: 

-- WRITES: 911DW:.fact_all_gateway_donations (InsertUpdate)
-- LOOKUP: 911DW:.dim_galaxy_items


-- ===== STEP: ti: Memorial Kiosk Donations, Coatcheck Donations [TableInput] conn=Gateway =====
SELECT     convert(varchar(10),JnlHeaders.TranDate,112) as key_date ,  Items.PLU,ISNULL(vA.rItmMatrixCode,'') 'AccountIDNo',
sum(JnlDetails.Qty) as Qty, 
sum(JnlDetails.Amount) as Amount
FROM         JnlHeaders (nolock) Left outer join
                      JnlDetails (nolock) ON JnlHeaders.JnlTranID = JnlDetails.JnlTranID 
                      Left outer join JnlItems (nolock) on JnlDetails.AuxTableID = JnlItems.JnlItemID
					  Left outer join Items (nolock) on JnlItems.Plu = Items.PLU 
					  left outer join report.vAttribute vA (nolock) on  Items.AttributeValueGroupID = vA.avgID
WHERE  
(
(ISNULL(vA.rItmMatrixCode,'') like '%DON-OPS-MEM%' ) or
(ISNULL(vA.rItmMatrixCode,'')  like '%DON-OPS-MUS%' )
)
and convert(varchar(10),JnlHeaders.TranDate,112) >= '20140516'
and JNLDetails.Qty <>0
group by 
convert(varchar(10),JnlHeaders.TranDate,112),
 Items.PLU,
ISNULL(vA.rItmMatrixCode,'') 
 order by key_date