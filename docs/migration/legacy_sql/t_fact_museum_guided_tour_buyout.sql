-- TRANSFORMATION: t_fact_museum_guided_tour_buyout
-- DESC: 

-- WRITES: 911DW:.fact_museum_guided_tour_buyout (InsertUpdate)
-- WRITES: 911DW:.fact_museum_guided_tour_buyout (InsertUpdate)
-- LOOKUP: 911DW:.dim_galaxy_items
-- LOOKUP: 911DW:.dim_galaxy_items


-- ===== STEP: Guided Tour Buyout [TableInput] conn=Gateway =====
SELECT
       CONVERT(VARCHAR(10),rmEvents.startDateTime,112) AS key_date
       ,jnlTickets.PLU
       ,ISNULL(vA.rItmMatrixCode,'') 'AccountIDNo'
       ,Items.Cost
       ,Items.Price
       ,SUM(jnlTickets.Tax) AS Tax
       ,SUM(
                     CASE
                           WHEN   jnlTickets.plu       IN       ('MEMGTOBUY001','MUSGTOBUY007','MUSGTOBUY009')  THEN   0
                           ELSE   JnlDetails.Qty
                     END
              )      AS Qty
       ,SUM(JnlDetails.Amount)    AS Amount
FROM
                                                              JnlHeaders
       INNER  JOIN   JnlDetails    ON     JnlHeaders.JnlTranID =      JnlDetails.JnlTranID 
       INNER  JOIN   jnlTickets    ON     JnlDetails.AuxTableID      =      jnlTickets.jnlDetailID
       INNER  JOIN   rmEvents      ON     jnlTickets.eventNo         =      rmEvents.eventID
       INNER  JOIN   Items         ON     jnlTickets.PLU                    =      Items.PLU
	   left outer join report.vAttribute vA (nolock) on  Items.AttributeValueGroupID = vA.avgID
WHERE
              CONVERT(VARCHAR(10),rmEvents.startDateTime,112) >=     dateadd(d,-1,?)
       AND    jnlTickets.plu       IN     (
                                                       'MUSGTOADR004'        
                                                       ,'MUSGTOADR007'        
                                                       ,'MEMGTOADR003'        
                                                       ,'MEMGTOBUY001'        
                                                       ,'MUSGTOBUY007'        
                                                       ,'MUSGTOBUY009'
														, 'MUSGTOCPR007'
                                                )
GROUP BY
       CONVERT(VARCHAR(10),rmEvents.startDateTime,112)
       ,jnlTickets.PLU
       ,ISNULL(vA.rItmMatrixCode,'') 
       ,Items.Cost
       ,Items.Price
ORDER BY
       key_date

-- ===== STEP: Guided Tour Buyout Additional Revenue [TableInput] conn=Gateway =====
select  convert(varchar(12),Expiration,112) as key_date, 
PLU, 
0 as Qty,
Price,
Tax
from Tickets
where PLU = 'TOUADDREV002'
and convert(varchar(12),Expiration,112) >= dateadd(d,-17,?)