-- TRANSFORMATION: t_fact_museum_donations_unissued
-- DESC: 

-- WRITES: 911DW:.fact_museum_donations_unissued (InsertUpdate)
-- LOOKUP: 911DW:.dim_galaxy_items


-- ===== STEP: Museum Donations- Unissued [TableInput] conn=Gateway =====
SELECT CONVERT(VARCHAR(12),Orders.OpenDate,112)as key_date ,
            Orders.OrderID,
            OrderLines.OrderLineID,
            Items.AccountIDNo, 
            Items.itemfilter, 
            Items.PLU,
            sum(OrderLines.Quantity-OrderLines.IssuedQuantity) as Quantity,
            sum(OrderLines.Amount) as Amount
  FROM Orders (nolock) inner join OrderLines (nolock)  
  ON Orders.OrderID = OrderLines.OrderID
  INNER JOIN Items (nolock) ON OrderLines.PLU = Items.PLU 
  WHERE 
(OrderLines.Quantity-OrderLines.IssuedQuantity)<>0 
        
        AND CONVERT(VARCHAR(12),Orders.OpenDate,112) >= dateadd(d,-323,?)
		
        
        AND (Items.AccountIDNo like '%MUS%' and Items.AccountIDNo like '%DON%')
       
  group by
CONVERT(VARCHAR(12),Orders.OpenDate,112) ,
Orders.OrderID,
OrderLines.OrderLineID,
OrderLines.Quantity,
OrderLines.IssuedQuantity,
Items.AccountIDNo, 
Items.itemfilter, 
Items.PLU
order by
key_date