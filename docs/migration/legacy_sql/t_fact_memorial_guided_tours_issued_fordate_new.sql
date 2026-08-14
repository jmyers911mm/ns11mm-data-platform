-- TRANSFORMATION: t_fact_memorial_guided_tours_issued_fordate_new
-- DESC: 

-- WRITES: 911DW:.fact_memorial_tours_issued_fordate_new (InsertUpdate)
-- LOOKUP: 911DW:.dim_galaxy_items


-- ===== STEP: Memorial Guided Tours - Issued [TableInput] conn=Gateway =====
SELECT
       CASE
             WHEN   vA.rItmRecognizeBasisID    =      182       THEN   CONVERT(VARCHAR(12),RMEvents.StartDateTime,112)
             WHEN   vA.rItmRecognizeBasisID    =      185       THEN   CONVERT(VARCHAR(12),jnlTickets.ticketDate,112)
			 WHEN	vA.rItmRecognizeBasisID	   =      349       THEN   CONVERT(VARCHAR(12),DATEADD(dd,14,jnlTickets.dateSold),112)
       END                                                                          'key_date'
       ,SUBSTRING(ISNULL(vA.rItmMatrixCode,''),1,3)          'VisitType'
       --,CONVERT(VARCHAR(12),RMEvents.StartDateTime,112)       'key_date'
       ,JNLTickets.OrderNo
       ,JnlTickets.VisualID
       ,ISNULL(vA.rItmMatrixCode,'')                                     'AccountIDNo'
       ,Items.PLU   
       ,Items.itemfilter
       ,JNLTickets.JnlDetailID
       ,SUM(Jnldetails.Qty)                                                     'Quantity'
       ,SUM(JNLdetails.Amount)                                                  'Amount'
       ,DisbursementDetails.[Name]
       ,CASE
             WHEN   JNLTickets.DisbursementID        =             0
                    AND    ISNULL(vA.rItmMatrixCode,'')       LIKE   'GAD%'              THEN   1
             WHEN   JNLTickets.DisbursementID        <>            0
                    AND    (
                                        ISNULL(vA.rItmMatrixCode,'')     LIKE   'TOU%'
                                 OR       ISNULL(vA.rItmMatrixCode,'')     LIKE   'MGT%'
                                 OR       ISNULL(vA.rItmMatrixCode,'')     LIKE   '%VTM%' -- Virtual Memorial Tour
                                 OR       ISNULL(vA.rItmMatrixCode,'')     LIKE   '%VTF%' -- Virtual Youth & Family Tour
                                 OR       ISNULL(vA.rItmMatrixCode,'')     LIKE   '%VTU%' -- Virtual Museum Tour
                                 OR       ISNULL(vA.rItmMatrixCode,'')     LIKE   '%VTE%' -- Virtual Memorial School Tour
                                 OR       ISNULL(vA.rItmMatrixCode,'')     LIKE   '%VTS%' -- Virtual Museum School Tour
                          )
                    AND    (
                                        ISNULL(DisbursementDetails.Name,'GEN ADM') = 'GEN ADM'
                          )
                    AND                 ISNULL(vA.rItmMatrixCode,'')     <>           '%XGA'       THEN   1
             ELSE                                                                                                            0
       END                                                                                  'GeneralAdmissionFlag'
FROM
                                       dbo.JnlDetails                   (nolock)
                          JOIN   dbo.JnlTickets                   (nolock)     ON           JnlDetails.AuxTableID             =      JnlTickets.JnlDetailID
                                                                                                         AND       JnlDetails.JnlcodeID             =      101
                          JOIN   dbo.Items                        (nolock)     ON           JnlTickets.PLU                         =      Items.PLU
                          JOIN   report.vAttribute vA       (nolock)     ON           Items.AttributeValueGroupID =       vA.avgID
                          JOIN   dbo.COA                                (nolock)     ON           jnldetails.AccountID             =      coa.AccountID
       LEFT OUTER   JOIN   dbo.DisbursementDetails (nolock) ON             jnltickets.DisbursementID  =       DisbursementDetails.DisbursementID
                                                                                                         AND       coa.GLCode                             =      101
                                                                                                         AND       coa.CompanyID                    =       DisbursementDetails.Company
                                                                                                         AND       coa.Category                     =       disbursementdetails.Category
                                                                                                         AND       coa.subcat                             =       DisbursementDetails.SubCategory
       LEFT OUTER   JOIN   dbo.RMEvents              (nolock)       ON           RMEvents.EventID                 =       JnlTickets.EventNo
WHERE
             (
                                 vA.rItmRecognizeBasisID                                           =      182
                          AND       CONVERT(VARCHAR(12),RMEvents.StartDateTime,112)      =       dateadd(d,-1,?)
                          --and CONVERT(VARCHAR(12),RMEvents.StartDateTime,112) < '20201001'
                    OR           vA.rItmRecognizeBasisID                                           =      185
                          AND       CONVERT(VARCHAR(12),jnlTickets.ticketDate,112) =       dateadd(d,-1,?)
                          --and CONVERT(VARCHAR(12),jnlTickets.ticketDate,112) < '20201001'
                   OR           vA.rItmRecognizeBasisID                                           =      349
                          AND       CONVERT(VARCHAR(12),DATEADD(dd,14,jnlTickets.dateSold),112) =       dateadd(d,-1,?)
             )
       AND    Items.PLU                                                                                   <>       'EXTEVENTAD001'
       AND    (
                          (
                                        ISNULL(vA.rItmMatrixCode,'')     LIKE   '%MGT%'
                                 OR       ISNULL(vA.rItmMatrixCode,'')     LIKE   '%VTM%' -- Virtual Memorial Tour
                                 OR       ISNULL(vA.rItmMatrixCode,'')     LIKE   '%VTF%' -- Virtual Youth & Family Tour
                                 OR       ISNULL(vA.rItmMatrixCode,'')     LIKE   '%VTU%' -- Virtual Museum Tour
                                 OR       ISNULL(vA.rItmMatrixCode,'')     LIKE   '%VTE%' -- Virtual Memorial School Tour
                                 OR       ISNULL(vA.rItmMatrixCode,'')     LIKE   '%VTS%' -- Virtual Museum School Tour
                          )
                    AND    ISNULL(vA.rItmMatrixCode,'')                  LIKE   '%XGA%'
             )
       AND    (
                          
                          vA.rItmDefaultCustomerID   NOT IN (
                                                                                            20056
                                                                                            ,23361
                                                                                     )
                    OR     vA.rItmDefaultCustomerID   IS            NULL
             )
GROUP BY
       CASE
             WHEN   vA.rItmRecognizeBasisID    =      182       THEN   CONVERT(VARCHAR(12),RMEvents.StartDateTime,112)
             WHEN   vA.rItmRecognizeBasisID    =      185       THEN   CONVERT(VARCHAR(12),jnlTickets.ticketDate,112)
			 WHEN	vA.rItmRecognizeBasisID	   =      349       THEN   CONVERT(VARCHAR(12),DATEADD(dd,14,jnlTickets.dateSold),112)
       END
       ,SUBSTRING(ISNULL(vA.rItmMatrixCode,''),1,3)
       --,CONVERT(VARCHAR(12),RMEvents.StartDateTime,112)
       ,JNLTickets.OrderNo
       ,JnlTickets.VisualID
       ,ISNULL(vA.rItmMatrixCode,'')
       ,Items.PLU   
       ,Items.itemfilter
       ,JNLTickets.JnlDetailID
       ,DisbursementDetails.[Name]
       ,CASE
             WHEN   JNLTickets.DisbursementID        =             0
                    AND    ISNULL(vA.rItmMatrixCode,'')       LIKE   'GAD%'              THEN   1
             WHEN   JNLTickets.DisbursementID        <>            0
                    AND    (
                                        ISNULL(vA.rItmMatrixCode,'')     LIKE   'TOU%'
                                 OR       ISNULL(vA.rItmMatrixCode,'')     LIKE   'MGT%'
                                 OR       ISNULL(vA.rItmMatrixCode,'')     LIKE   '%VTM%' -- Virtual Memorial Tour
                                 OR       ISNULL(vA.rItmMatrixCode,'')     LIKE   '%VTF%' -- Virtual Youth & Family Tour
                                 OR       ISNULL(vA.rItmMatrixCode,'')     LIKE   '%VTU%' -- Virtual Museum Tour
                                 OR       ISNULL(vA.rItmMatrixCode,'')     LIKE   '%VTE%' -- Virtual Memorial School Tour
                                 OR       ISNULL(vA.rItmMatrixCode,'')     LIKE   '%VTS%' -- Virtual Museum School Tour
                          )
                    AND    (
                                        ISNULL(DisbursementDetails.Name,'GEN ADM') = 'GEN ADM'
                          )
                    AND                 ISNULL(vA.rItmMatrixCode,'')     <>           '%XGA'       THEN   1
             ELSE                                                                                                            0
       END

UNION ALL

SELECT
       --CONVERT(VARCHAR(12),jnlHeaders.fiscalDate,112)           'EventDate'
       SUBSTRING(ISNULL(vA.rItmMatrixCode,''), 1,3)          'VisitType'
       ,CONVERT(VARCHAR(12),jnlHeaders.fiscalDate,112)             'key_date'
       ,orderLines.orderID
       ,null                                                                         'VisualID'
       ,ISNULL(vA.rItmMatrixCode,'')                                     'AccountIDNo'
       ,Items.PLU
       ,Items.itemfilter
       ,JNLitems.jnlItemID
       ,SUM(Jnldetails.Qty)                                                     'Quantity'
       ,SUM(JNLdetails.Amount)                                                  'Amount'
       ,null                                                                         'Name'
       ,0                                                                                   'GeneralAdmissionFlag'
FROM
                                       dbo.JnlDetails                   (nolock)
                          JOIN   dbo.jnlHeaders                   (noLock)     ON     jnlDetails.jnlTranID             =       jnlHeaders.jnlTranID
                          JOIN   dbo.JnlItems               (nolock)     ON     JnlDetails.AuxTableID            =       JnlItems.JnlItemID
                                                                                                  AND       JnlDetails.JnlcodeID             IN     (
                                                                                                                                                                    102
                                                                                                                                                                    ,103
                                                                                                                                                                    ,104
                                                                                                                                                             )
       LEFT OUTER   JOIN   orderLines                       (noLock)     ON     jnlDetails.orderlineID           =       orderLines.orderLineID
       LeFT OUTER   JOIN   dbo.Items                        (noLock)     ON     jnlItems.PLU                     =       Items.PLU
       LEFT OUTER   JOIN   report.vAttribute vA       (nolock)       ON     Items.AttributeValueGroupID =    vA.avgID
       LEFT OUTER   JOIN   dbo.COA                                 (nolock)     ON     jnldetails.AccountID             =       coa.AccountID
WHERE
             CONVERT(VARCHAR(12),jnlHeaders.fiscalDate,112) = dateadd(d,-1,?)
             --and CONVERT(VARCHAR(12),jnlHeaders.fiscalDate,112) < '20201001'
       AND    Items.PLU                                                               =      'VTPREMGTOADW001'
       AND    (
                          (
                                        ISNULL(vA.rItmMatrixCode,'')     LIKE   '%MGT%'
                                 OR       ISNULL(vA.rItmMatrixCode,'')     LIKE   '%VTM%' -- Virtual Memorial Tour
                                 OR       ISNULL(vA.rItmMatrixCode,'')     LIKE   '%VTF%' -- Virtual Youth & Family Tour
                                 OR       ISNULL(vA.rItmMatrixCode,'')     LIKE   '%VTU%' -- Virtual Museum Tour
                                 OR       ISNULL(vA.rItmMatrixCode,'')     LIKE   '%VTE%' -- Virtual Memorial School Tour
                                 OR       ISNULL(vA.rItmMatrixCode,'')     LIKE   '%VTS%' -- Virtual Museum School Tour
                          )
                    AND    ISNULL(vA.rItmMatrixCode,'')                         LIKE   '%XGA%'
             )
       AND    (
                          
                          vA.rItmDefaultCustomerID   NOT IN (
                                                                                            20056
                                                                                            ,23361
                                                                                     )
                    OR     vA.rItmDefaultCustomerID   IS            NULL
             )
GROUP BY
       --CONVERT(VARCHAR(12),jnlHeaders.fiscalDate,112)    
       SUBSTRING(ISNULL(vA.rItmMatrixCode,''), 1,3)
       ,CONVERT(VARCHAR(12),jnlHeaders.fiscalDate,112)
       ,orderLines.orderID
       ,ISNULL(vA.rItmMatrixCode,'')
       ,Items.PLU
       ,Items.itemfilter
       ,JNLitems.jnlItemID