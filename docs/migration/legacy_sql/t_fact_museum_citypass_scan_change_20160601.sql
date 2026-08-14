-- TRANSFORMATION: t_fact_museum_citypass_scan_change_20160601
-- DESC: 

-- WRITES: 911DW:.fact_museum_citypass_scanchange (InsertUpdate)
-- LOOKUP: 911DW:.dim_citypass_revenue
-- LOOKUP: 911DW:.dim_galaxy_items


-- ===== STEP: CityPASS Tickets [TableInput] conn=Gateway =====
SELECT
  CONVERT(varchar(12), u.useTime, 112) AS 'key_date',
  '0' AS 'OrderNo',
  u.visualID AS 'VisualID',
  ISNULL(vA.rItmMatrixCode,'') 'AccountIDNo',
  CASE
    WHEN  vA.rItmDefaultCustomerID = 20056 and vA.rItmPricePointID = 83 THEN 'Adult'
    WHEN  vA.rItmDefaultCustomerID = 23361 and vA.rItmPricePointID = 83 THEN 'C3 Adult'
    WHEN vA.rItmDefaultCustomerID = 20056 and vA.rItmPricePointID = 86 THEN 'Youth'
    WHEN vA.rItmDefaultCustomerID = 23361 and vA.rItmPricePointID = 86  THEN 'C3 Youth'
    ELSE 'None'
  END AS ItemsName,
  u.plu 'plu',
  i.itemFilter 'itemFilter',
  '0' 'jnlDetailID',
  SUM(u.quantity) 'quantity',
  '' AS 'amount'
FROM report.vUsage u
JOIN items i   ON u.plu = i.plu
left outer Join Report.vAttribute vA on i.AttributeValueGroupID = vA.avgID and vA.rItmDefaultCustomerID in ( 20056, 23361)
WHERE 

u.statusID IN (0, 23, 46)
and vA.rItmDefaultCustomerID in ( 20056, 23361)
and vA.rItmProductID = 77
AND CONVERT(varchar(8), u.useTime, 112) >=  '20181226'
and convert(varchar(8), u.useTime, 112) <=  '20201109'
GROUP BY u.useTime,
         u.visualID,
        ISNULL(vA.rItmMatrixCode,''),
         CASE
            WHEN  vA.rItmDefaultCustomerID = 20056 and vA.rItmPricePointID = 83 THEN 'Adult'
    		WHEN  vA.rItmDefaultCustomerID = 23361 and vA.rItmPricePointID = 83 THEN 'C3 Adult'
   			WHEN vA.rItmDefaultCustomerID = 20056 and vA.rItmPricePointID = 86 THEN 'Youth'
    		WHEN vA.rItmDefaultCustomerID = 23361 and vA.rItmPricePointID = 86  THEN 'C3 Youth'
    		ELSE 'None'
         END,
         u.plu,
         i.itemFilter
order by CONVERT(varchar(8), u.useTime, 112)