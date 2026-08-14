-- TRANSFORMATION: t_fact_museum_bulk_ticket_scans
-- DESC: 

-- WRITES: 911DW:.fact_museum_bulk_tickets (InsertUpdate)
-- WRITES: 911DW:.fact_museum_bulk_tickets_test (InsertUpdate)
-- LOOKUP: 911DW:.dim_galaxy_items
-- LOOKUP: 911DW:.dim_bulk_tickets_revenue
-- LOOKUP: 911DW:.dim_galaxy_items


-- ===== STEP: Museum Bulk Tickets Scanned [TableInput] conn=Gateway =====
SELECT 
  CONVERT(varchar(12), u.UseTime, 112) AS 'key_date',
  u.visualID AS 'VisualID',
  i.accountIDNo AS 'AccountIDNo',
  t.plu 'plu',
  i.itemFilter 'itemFilter',
    SUM(t.qty) 'quantity',
  '' AS 'amount',
CASE
    WHEN t.plu IN ('MUSGRPADR007','MUSGRPSRR007') THEN 'Adult'
    WHEN t.plu IN ('MUSGRPYSR007') THEN 'Youth'
    ELSE 'None'
  END AS ItemsName
FROM usage u
JOIN tickets t ON u.visualID = t.visualID
JOIN items i   ON t.plu = i.plu
WHERE u.status IN (0, 6, 23, 46)
and i.plu in ('MUSGRPADR007','MUSGRPSRR007','MUSGRPYSR007')
AND CONVERT(varchar(8), u.UseTime, 112) >=  '20170401'
GROUP BY u.UseTime,
         u.visualID,
         i.accountIDNo,
         t.plu,
         i.itemFilter
order by CONVERT(varchar(12), u.UseTime, 112)

-- ===== STEP: Table input [TableInput] conn=Gateway =====
SELECT 
CONVERT(varchar(12), vU.usetime,112) as key_date, 
vU.UsageID, 
vU.VisualID, 
vU.OrderID,
vA.rItmPricePointID,
vA.rItmDefaultCustomerID,
vU.plu,
vU.itmDescr,
vU.quantity, 
vU.amount
                             
                FROM
                                report.vUsage   vU
                                                       LEFT OUTER    JOIN   report.vAttribute    vA     ON     vU.itmAvgID   =      vA.avgID

                                  

                WHERE
                                                CONVERT(varchar(12), vU.usetime,112)       =  ?
                                                       AND ((rItmDefaultCustomerID not in (20056,23361)) or rItmDefaultCustomerID is NULL)
                                AND       vU.statusID        IN           (0,23,46)
                                AND       isnull(vU.eventID,0)         =             0
                                AND       (
                                                  vU.facilityID        =             7
                                                  AND       vU.plu   NOT IN (
                                                                        'MUSGADEXW001'
                                                                       ,'CPBOOKYS011'
                                                                       ,'CPBOOKAD011'
                                                                       ,'CPBOOKAD010'
                                                                       ,'CPBOOKYS010'
                                                                          )
                                                  OR
                                                  vU.facilityID        =                18
                                          )
                                                       AND vA.rItmPricePointID is not null
                           order by CONVERT(varchar(12), vU.usetime,112)