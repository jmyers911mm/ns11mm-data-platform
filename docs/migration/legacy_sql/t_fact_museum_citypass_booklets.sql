-- TRANSFORMATION: t_fact_museum_citypass_booklets
-- DESC: 

-- WRITES: 911DW:.fact_museum_citypass_booklets (TableOutput)
-- LOOKUP: 911DW:.dim_galaxy_items


-- ===== STEP: CityPASS Booklets [TableInput] conn=Gateway =====
SELECT
CONVERT(VARCHAR(12),jnlHeaders.fiscalDate,112) as key_date,
JNLTickets.OrderNo,
JnlTickets.VisualID,
ISNULL(vA.rItmMatrixCode,'') 'AccountIDNo',
CASE
       WHEN   jnlTickets.plu       IN     (
                                                       'MUSGADADCP001',
                                                       'MUSGADADCP003',
                                                       'MUSGADADCP005',
														'MUSGADCMCP002'       

                                                )                                 THEN   'Adult'
       WHEN   jnlTickets.plu       IN     (
                                                       'MUSGADYSCP001',
                                                       'MUSGADYSCP003',
                                                       'MUSGADYSCP005'
                                                )                                 THEN   'Youth'
       ELSE                                                                              'None'
END           as     ItemsName,
jnlTickets.PLU,
Items.itemfilter, 
JNLTickets.JnlDetailID,
SUM(Jnldetails.Qty) as Quantity,
SUM(JNLdetails.Amount) as Amount
          
FROM
       dbo.jnlHeaders
       JOIN   dbo.jnlDetails       ON     jnlHeaders.jnlTranID =      dbo.jnlDetails.jnlTranID

     Left outer join dbo.JnlTickets on        JnlDetails.AuxTableID = JnlTickets.JnlDetailID and JnlDetails.JnlcodeID = 101
     left outer join dbo.Items on JnlTickets.PLU = Items.PLU
	 left outer join report.vAttribute vA (nolock) on  Items.AttributeValueGroupID = vA.avgID
     left outer join dbo.COA on jnldetails.AccountID = coa.AccountID
                                   
where                      
       CONVERT(VARCHAR(12),jnlheaders.fiscalDate,112) >= '20160601'
AND    items.plu IN  (
                                         'MUSGADADCP001',
                                         'MUSGADADCP003',
                                         'MUSGADADCP005',
                                         'MUSGADYSCP001',
                                         'MUSGADYSCP003',
                                         'MUSGADYSCP005'
                                  )
group by
jnlheaders.fiscalDate,
JNLTickets.OrderNo,
JnlTickets.VisualID,
ISNULL(vA.rItmMatrixCode,''), 
jnlTickets.PLU,
Items.itemfilter, 
JNLTickets.JnlDetailID
order by 
CONVERT(VARCHAR(12),jnlheaders.fiscaldate,112)