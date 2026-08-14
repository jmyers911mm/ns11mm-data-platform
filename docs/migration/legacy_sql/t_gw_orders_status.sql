-- TRANSFORMATION: t_gw_orders_status
-- DESC: 



-- ===== STEP: Get_Fact_Orders_Status [TableInput] conn=Gateway Prod =====
IF NOT EXISTS(
SELECT TOP 1 OpenDate 
FROM dbo.orders  (NOLOCK)
WHERE OpenDate > DATEADD(MINUTE,-60,GETDATE())
ORDER BY OpenDate DESC
)
BEGIN
	SELECT 0 AS NextStep
END
ELSE
BEGIN
	SELECT 1 AS NextStep
END