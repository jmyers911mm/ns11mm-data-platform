-- TRANSFORMATION: t_fact_museum_galaxy_tickets
-- DESC: 

-- WRITES: 911DW:.fact_museum_galaxy_tickets (TableOutput)
-- LOOKUP: 911DW:.dim_galaxy_items


-- ===== STEP: Museum Tickets [TableInput] conn=Gateway =====
SELECT     CONVERT(VARCHAR(12),Orders.OpenDate,112) as key_date,
Orders.OrderID,
Orders.Balance as Balance, 
Items.itemfilter, 
Items.AccountIDNo, 
Items.Descr, 
Items.PLU,
case when CONVERT(VARCHAR(12),Orders.OpenDate,112) < '20150301' and Items.AccountIDNo like '%TOU%' THEN '18'
when CONVERT(VARCHAR(12),Orders.OpenDate,112) >= '20150301' and Items.AccountIDNo like '%TOU%' THEN '20'
else 0 END Tour_Amt,
sum(OrderLines.Quantity) as Quantity, 
sum(OrderLines.Amount) as Amount, 
sum(OrderLines.Total) as Total
FROM         Orders (nolock) INNER JOIN
                      OrderLines (nolock) ON Orders.OrderID = OrderLines.OrderID INNER JOIN
                      Items (nolock) ON OrderLines.PLU = Items.PLU

where  CONVERT(VARCHAR(12),Orders.OpenDate,112) >= '20140326'
group by
CONVERT(VARCHAR(12),Orders.OpenDate,112),
Orders.OrderID,
Orders.Balance,
Items.itemfilter,
Items.AccountIDNo,
Items.Descr,
Items.PLU

order by 
Orders.OrderID,
key_date