-- TRANSFORMATION: t_dim_museum_ticket_types
-- DESC: 

-- WRITES: 911DW:.dim_museum_tickets (InsertUpdate)


-- ===== STEP: Museum Tickets [TableInput] conn=Gateway =====
SELECT    distinct  Items.AccountIDNo, Items.Descr
FROM         Orders (nolock) INNER JOIN
                      OrderLines (nolock) ON Orders.OrderID = OrderLines.OrderID INNER JOIN
                      Items (nolock) ON OrderLines.PLU = Items.PLU