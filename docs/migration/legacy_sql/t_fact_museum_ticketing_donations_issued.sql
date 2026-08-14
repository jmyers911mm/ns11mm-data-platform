-- TRANSFORMATION: t_fact_museum_ticketing_donations_issued
-- DESC: 

-- WRITES: 911DW:.fact_museum_ticketing_donations_issued (TableOutput)
-- LOOKUP: 911DW:.dim_galaxy_items


-- ===== STEP: Museum Ticketing Donations - Issued [TableInput] conn=Gateway =====
select
case when JnlHeaders.JnlTranID='12383495' then CONVERT(VARCHAR(12), JnlHeaders.FiscalDate,112) 
else CONVERT(VARCHAR(12),JnlHeaders.TranDate,112) end as key_date,
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
                    
                     
                      CONVERT(VARCHAR(12),JnlHeaders.TranDate,112) >= '20140326'
						and (ISNULL(vA.rItmMatrixCode,'') like '%MUS%' and ISNULL(vA.rItmMatrixCode,'') like '%DON%')
                     
group by
case when JnlHeaders.JnlTranID='12383495' then CONVERT(VARCHAR(12), JnlHeaders.FiscalDate,112) 
else CONVERT(VARCHAR(12),JnlHeaders.TranDate,112) end ,
ISNULL(vA.rItmMatrixCode,''), 
Items.PLU,
Items.itemfilter 
order by 
case when JnlHeaders.JnlTranID='12383495' then CONVERT(VARCHAR(12), JnlHeaders.FiscalDate,112) 
else CONVERT(VARCHAR(12),JnlHeaders.TranDate,112) end