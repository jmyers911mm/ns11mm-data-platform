-- TRANSFORMATION: t_fact_service_fees_new
-- DESC: 

-- WRITES: 911DW:.fact_service_fees_new (TableOutput)
-- LOOKUP: 911DW:.dim_galaxy_items


-- ===== STEP: ti: Memorial Service Fees [TableInput] conn=Gateway =====
select CONVERT(VARCHAR(12),JnlHeaders.TranDate,112) as key_date,

ISNULL(vA.rItmMatrixCode,'') 'AccountIDNo', 
Items.PLU,
Items.itemfilter, 

SUM(JnlDetails.Qty) as Quantity,
SUM(JnlDetails.Amount) as Amount

FROM                  
						JnlHeaders (nolock) 
						INNER JOIN JnlDetails (nolock) on JnlHeaders.jnltranid = JnlDetails.jnltranid
                        INNER JOIN JnlItems (nolock) on JnlDetails.AuxTableID = JnlItems.JnlItemID and jnlcodeid in (102,103,104)
						INNER JOIN Items (nolock) on JnlItems.plu=Items.plu
						left outer join report.vAttribute vA (nolock) on  Items.AttributeValueGroupID = vA.avgID
            where
                      
                     
                      CONVERT(VARCHAR(12),JnlHeaders.TranDate,112) >= '20150401'
						and (ISNULL(vA.rItmMatrixCode,'') like '%MEF%' and ISNULL(vA.rItmMatrixCode,'') like '%FEE%')
                     
group by
CONVERT(VARCHAR(12),JnlHeaders.TranDate,112) ,
ISNULL(vA.rItmMatrixCode,''), 
Items.PLU,
Items.itemfilter 
order by 
CONVERT(VARCHAR(12),JnlHeaders.TranDate,112)

-- ===== STEP: ti: Museum Service Fees [TableInput] conn=Gateway =====
select CONVERT(VARCHAR(12),JnlHeaders.TranDate,112) as key_date,
ISNULL(vA.rItmMatrixCode,'') 'AccountIDNo', 
Items.PLU,
Items.itemfilter, 
SUM(JnlDetails.Qty) as Quantity,
SUM(JnlDetails.Amount) as Amount
FROM                  
                     JnlHeaders (nolock) 
                     INNER JOIN JnlDetails (nolock) on JnlHeaders.jnltranid = JnlDetails.jnltranid
                     LEFT OUTER JOIN     jnlTickets    ON     jnlDetails.jnlCodeID =       101 and jnlDetails.auxTableID     =      jnlTickets.jnlDetailID
                     LEFT OUTER JOIN     JnlItems (nolock) on JnlDetails.AuxTableID = JnlItems.JnlItemID and jnlcodeid in (102,103,104)
                     LEFT OUTER   JOIN Items (nolock) on ISNULL(JnlItems.plu,jnlTickets.plu)=Items.plu
					  left outer join report.vAttribute vA (nolock) on  Items.AttributeValueGroupID = vA.avgID
            where
             CONVERT(VARCHAR(12),JnlHeaders.TranDate,112) >= '20140326'
              and (ISNULL(vA.rItmMatrixCode,'')  like '%MUF%' and ISNULL(vA.rItmMatrixCode,'') like '%FEE%')
                     
group by
CONVERT(VARCHAR(12),JnlHeaders.TranDate,112) ,
ISNULL(vA.rItmMatrixCode,''), 
Items.PLU,
Items.itemfilter 
order by 
CONVERT(VARCHAR(12),JnlHeaders.TranDate,112)