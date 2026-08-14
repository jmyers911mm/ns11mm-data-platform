-- TRANSFORMATION: t_fact_museum_galaxy_payments
-- DESC: 

-- WRITES: 911DW:.fact_museum_payments (TableOutput)


-- ===== STEP: Galaxy Payments [TableInput] conn=Gateway =====
SELECT     
CONVERT(varchar(12),OrderPayments.PaymentDate,112) as key_date, 
OrderPayments.OrderLineID, 
OrderPayments.PaymentFOP, 
OrderPayments.PaymentAmount, 
OrderLines.OrderID
FROM         
OrderPayments (nolock) INNER JOIN
OrderLines (nolock) ON OrderPayments.OrderLineID = OrderLines.OrderLineID
WHERE(Orderlines.orderid in 
(SELECT     Orders.OrderID
FROM         Orders(nolock) INNER JOIN
OrderLines(nolock) ON Orders.OrderID = OrderLines.OrderID INNER JOIN
Items(nolock) ON OrderLines.PLU = Items.PLU
WHERE     
Items.ItemFilter = 'm')) 
and OrderPayments.PaymentFOP < 50 
and CONVERT(varchar(12),OrderPayments.PaymentDate,112)>='20140326'
and CONVERT(varchar(12),OrderPayments.PaymentDate,112) < ?
Order by OrderLines.OrderID,
OrderPayments.PaymentDate