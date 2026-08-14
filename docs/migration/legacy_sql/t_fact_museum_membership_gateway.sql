-- TRANSFORMATION: t_fact_museum_membership_gateway
-- DESC: 

-- WRITES: 911DW:.fact_museum_membership_gw (InsertUpdate)


-- ===== STEP: Gateway- Museum Memberships [TableInput] conn=Gateway =====
SELECT     convert(varchar(10),JnlHeaders.TranDate,112) as key_date ,JnlTickets.OrderNo, JnlDetails.Qty, JnlDetails.Amount
FROM         JnlHeaders INNER JOIN
                      JnlDetails ON JnlHeaders.JnlTranID = JnlDetails.JnlTranID INNER JOIN
                      JnlTickets ON JnlDetails.JnlDetailID = JnlTickets.JnlDetailID INNER JOIN
                      Items ON JnlTickets.PLU = Items.PLU
WHERE   (Items.Kind IN ('2', '6', '7'))
and  convert(varchar(10),JnlHeaders.TranDate,112)<=convert(varchar(10),GETDATE(),112)-1 
order by key_date