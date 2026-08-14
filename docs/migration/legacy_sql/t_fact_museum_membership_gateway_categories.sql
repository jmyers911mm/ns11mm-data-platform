-- TRANSFORMATION: t_fact_museum_membership_gateway_categories
-- DESC: 

-- WRITES: 911DW:.fact_museum_membership_gw (InsertUpdate)
-- WRITES: 911DW:.fact_museum_membership_gw (InsertUpdate)
-- WRITES: 911DW:.fact_museum_membership_gw (InsertUpdate)


-- ===== STEP: Gateway- Box office Museum Memberships [TableInput] conn=Gateway =====
SELECT     convert(varchar(10),JnlHeaders.TranDate,112) as key_date ,
JnlTickets.JnlDetailID as OrderNo , 
JNLTickets.NodeNo,
JnlDetails.Qty, 
JnlDetails.Amount
FROM         JnlHeaders INNER JOIN
                      JnlDetails ON JnlHeaders.JnlTranID = JnlDetails.JnlTranID INNER JOIN
                      JnlTickets ON JnlDetails.JnlDetailID = JnlTickets.JnlDetailID INNER JOIN
                      Items ON JnlTickets.PLU = Items.PLU
WHERE   (Items.Kind IN ('2', '6', '7'))
and JNLTickets.NodeNo in 
('8',
'300',
'301',
'302',
'303',
'304',
'305',
'306')
and  convert(varchar(10),JnlHeaders.TranDate,112)=convert(varchar(10),DATEADD (dd,-1, convert(varchar(10),GETDATE(),112)),112) 
order by key_date

-- ===== STEP: Gateway- Info Desk Museum Memberships [TableInput] conn=Gateway =====
SELECT     convert(varchar(10),JnlHeaders.TranDate,112) as key_date ,
JnlTickets.JnlDetailID as OrderNo ,
JNLTickets.NodeNo, 
JnlDetails.Qty, 
JnlDetails.Amount
FROM         JnlHeaders INNER JOIN
                      JnlDetails ON JnlHeaders.JnlTranID = JnlDetails.JnlTranID INNER JOIN
                      JnlTickets ON JnlDetails.JnlDetailID = JnlTickets.JnlDetailID INNER JOIN
                      Items ON JnlTickets.PLU = Items.PLU
WHERE   (Items.Kind IN ('2', '6', '7'))
and JNLTickets.NodeNo in 
('330',
'331',
'332',
'333',
'334',
'335',
'336',
'337')
and  convert(varchar(10),JnlHeaders.TranDate,112)=convert(varchar(10),DATEADD (dd,-1, convert(varchar(10),GETDATE(),112)),112)
order by key_date

-- ===== STEP: Gateway- Online Museum Memberships [TableInput] conn=Gateway =====
SELECT     convert(varchar(10),JnlHeaders.TranDate,112) as key_date ,JnlTickets.OrderNo,JNLTickets.NodeNo, JnlDetails.Qty, JnlDetails.Amount
FROM         JnlHeaders INNER JOIN
                      JnlDetails ON JnlHeaders.JnlTranID = JnlDetails.JnlTranID INNER JOIN
                      JnlTickets ON JnlDetails.JnlDetailID = JnlTickets.JnlDetailID INNER JOIN
                      Items ON JnlTickets.PLU = Items.PLU
WHERE   (Items.Kind IN ('2', '6', '7'))
and JNLTickets.NodeNo in 
('3',
'4',
'5',
'6',
'7',
'31',
'32',
'33',
'34',
'500',
'501',
'502',
'503',
'504',
'505',
'506',
'507')
and  convert(varchar(10),JnlHeaders.TranDate,112)=convert(varchar(10),DATEADD (dd,-1, convert(varchar(10),GETDATE(),112)),112) 
order by key_date