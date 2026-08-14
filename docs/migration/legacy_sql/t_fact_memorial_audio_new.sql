-- TRANSFORMATION: t_fact_memorial_audio_new
-- DESC: 

-- WRITES: 911DW:.fact_memorial_audio_new (InsertUpdate)
-- LOOKUP: 911DW:.dim_galaxy_items


-- ===== STEP: ti2: Audio Guides from JnlTickets [TableInput] conn=Gateway =====
SELECT     
	CONVERT(VARCHAR(8),JnlHeaders.TranDate,112) AS key_date, 
	jnlTickets.PLU,ISNULL(vA.rItmMatrixCode,'') 'AccountIDNo',
	Items.Cost,
	Items.Price, 
	CAST(SUM(jnlTickets.Tax) AS DECIMAL(19,4)) AS Tax,
	SUM(JnlDetails.Qty) AS Qty, 
	SUM(JnlDetails.Amount) AS Amount
FROM  JnlHeaders (NOLOCK) 
			INNER JOIN JnlDetails ON JnlHeaders.JnlTranID = JnlDetails.JnlTranID and JnlDetails.JnlCodeID=101
			LEFT OUTER JOIN jnlTickets (NOLOCK) ON JnlDetails.AuxTableID=jnlTickets.jnlDetailID
			INNER JOIN  Items (NOLOCK) ON jnlTickets.PLU = Items.PLU
			LEFT OUTER JOIN report.vAttribute vA (NOLOCK) ON  Items.AttributeValueGroupID = vA.avgID
WHERE (Items.Kind IN (1,5)) 
AND (jnlTickets.PLU IN ('AUDIO0014','AUDIO0015','AUDIO0016','AUDIO0017','AUDIO0018','AUDIO0019') )
AND  CONVERT(VARCHAR(10),JnlHeaders.TranDate,112) >= '20230404'
GROUP BY 
CONVERT(VARCHAR(8),JnlHeaders.TranDate,112),
jnlTickets.PLU,
ISNULL(vA.rItmMatrixCode,''),
Items.Price,
Items.Cost
UNION
SELECT     
	CONVERT(VARCHAR(8),ev.StartDateTime,112)  as key_date,
	jnlTickets.PLU,ISNULL(vA.rItmMatrixCode,'') 'AccountIDNo',
	Items.Cost,
	Items.Price, 
	CAST(SUM(jnlTickets.Tax) AS DECIMAL(19,4)) AS Tax,
	SUM(JnlDetails.Qty) AS Qty, 
	SUM(JnlDetails.Amount) AS Amount
FROM  JnlHeaders (NOLOCK) 
			INNER JOIN JnlDetails ON JnlHeaders.JnlTranID = JnlDetails.JnlTranID and JnlDetails.JnlCodeID=101
			LEFT OUTER JOIN jnlTickets (NOLOCK) ON JnlDetails.AuxTableID=jnlTickets.jnlDetailID
			LEFT OUTER JOIN [dbo].[RMEvents] (NOLOCK) ev ON jnlTickets.EventNo = ev.EventID
			INNER JOIN  Items ON jnlTickets.PLU = Items.PLU
			LEFT OUTER JOIN report.vAttribute vA (NOLOCK) ON  Items.AttributeValueGroupID = vA.avgID
WHERE (Items.Kind IN (1,5)) 
AND (jnlTickets.PLU IN ('AUDIOWEB01') )
AND  CONVERT(VARCHAR(10),JnlHeaders.TranDate,112) >= '20230516'
GROUP BY 
CONVERT(VARCHAR(8),ev.StartDateTime,112),
jnlTickets.PLU,
ISNULL(vA.rItmMatrixCode,''),
Items.Price,
Items.Cost

-- ===== STEP: ti: Audio Guides from JnlItems [TableInput] conn=Gateway =====
SELECT     
	CONVERT(VARCHAR(8),JnlHeaders.TranDate,112) AS key_date, 
	JNLItems.PLU,ISNULL(vA.rItmMatrixCode,'') 'AccountIDNo',
	Items.Cost,
	Items.Price, 
	CAST(SUM(JNLItems.Tax) AS decimal(19,4)) 
	AS Tax,SUM(JnlDetails.Qty) AS Qty, 
	SUM(JnlDetails.Amount) AS Amount
FROM JnlHeaders (NOLOCK) 
				INNER JOIN JnlDetails (NOLOCK) ON JnlHeaders.JnlTranID = JnlDetails.JnlTranID and JnlDetails.JnlCodeID=102
				LEFT OUTER JOIN JnlItems (NOLOCK) ON JnlDetails.AuxTableID=JnlItems.JnlItemID
				INNER JOIN  Items (NOLOCK) ON JnlItems.PLU = Items.PLU
				LEFT OUTER JOIN report.vAttribute vA (NOLOCK) ON  Items.AttributeValueGroupID = vA.avgID
WHERE (Items.Kind IN ('8')) 
AND (JnlItems.PLU IN ('AUDIO1011','AUDIO0011') )
AND  CONVERT(VARCHAR(10),JnlHeaders.TranDate,112) >= '20230404'
GROUP BY 
CONVERT(VARCHAR(8),JnlHeaders.TranDate,112),
JNLItems.PLU,
ISNULL(vA.rItmMatrixCode,''),
Items.Price,
Items.Cost
UNION
SELECT     
	CONVERT(VARCHAR(8),ev.StartDateTime,112)  as key_date,
	JNLItems.PLU,ISNULL(vA.rItmMatrixCode,'') 'AccountIDNo',
	Items.Cost,
	Items.Price, 
	CAST(SUM(JNLItems.Tax) AS decimal(19,4)) 
	AS Tax,SUM(JnlDetails.Qty) AS Qty, 
	SUM(JnlDetails.Amount) AS Amount
FROM JnlHeaders (NOLOCK) 
				INNER JOIN JnlDetails (NOLOCK) ON JnlHeaders.JnlTranID = JnlDetails.JnlTranID and JnlDetails.JnlCodeID=102
				LEFT OUTER JOIN jnlTickets (NOLOCK) ON JnlDetails.AuxTableID=jnlTickets.jnlDetailID
			    LEFT OUTER JOIN [dbo].[RMEvents] (NOLOCK) ev ON jnlTickets.EventNo = ev.EventID
				LEFT OUTER JOIN JnlItems (NOLOCK) ON JnlDetails.AuxTableID=JnlItems.JnlItemID
				INNER JOIN  Items ON JnlItems.PLU = Items.PLU
				LEFT OUTER JOIN report.vAttribute vA (NOLOCK) ON  Items.AttributeValueGroupID = vA.avgID
WHERE (Items.Kind IN ('8')) 
AND (JnlItems.PLU IN ('AUDIOWEB01') )
AND  CONVERT(VARCHAR(10),JnlHeaders.TranDate,112) >= '20230516'
GROUP BY 
CONVERT(VARCHAR(8),ev.StartDateTime,112),
JNLItems.PLU,
ISNULL(vA.rItmMatrixCode,''),
Items.Price,
Items.Cost