-- TRANSFORMATION: t_fact_retail
-- DESC: Retail Fact

-- WRITES: 911DW:.fact_retail (InsertUpdate)
-- WRITES: 911DW:.fact_retail (InsertUpdate)
-- WRITES: 911DW:.fact_retail (InsertUpdate)
-- WRITES: 911DW:.fact_retail (InsertUpdate)
-- WRITES: 911DW:.fact_retail (InsertUpdate)
-- WRITES: 911DW:.fact_retail (InsertUpdate)
-- WRITES: 911DW:.fact_retail (InsertUpdate)
-- LOOKUP: 911DW:.dim_item_descr
-- LOOKUP: 911DW:.dim_item_descr
-- LOOKUP: 911DW:.dim_item_descr
-- LOOKUP: 911DW:.dim_item_descr
-- LOOKUP: 911DW:.dim_item_descr
-- LOOKUP: 911DW:.dim_item_descr
-- LOOKUP: 911DW:.dim_category
-- LOOKUP: 911DW:.dim_category
-- LOOKUP: 911DW:.dim_category
-- LOOKUP: 911DW:.dim_category
-- LOOKUP: 911DW:.dim_category
-- LOOKUP: 911DW:.dim_category
-- LOOKUP: 911DW:.dim_sub_category
-- LOOKUP: 911DW:.dim_sub_category
-- LOOKUP: 911DW:.dim_sub_category
-- LOOKUP: 911DW:.dim_sub_category
-- LOOKUP: 911DW:.dim_sub_category
-- LOOKUP: 911DW:.dim_sub_category
-- LOOKUP: 911DW:.dim_category
-- LOOKUP: 911DW:.dim_category
-- LOOKUP: 911DW:.dim_category
-- LOOKUP: 911DW:.dim_category
-- LOOKUP: 911DW:.dim_category
-- LOOKUP: 911DW:.dim_category
-- LOOKUP: 911DW:.dim_item_descr
-- LOOKUP: 911DW:.dim_category
-- LOOKUP: 911DW:.dim_sub_category
-- LOOKUP: 911DW:.dim_category


-- ===== STEP: CounterPoint - Sales [TableInput] conn=Counterpoint =====
select
LINE.ITEM_NO,
CONVERT(VARCHAR(10), LINE.BUS_DAT, 112) AS key_date,
1002 as key_facility,
    case when RTRIM(LTRIM(LINE.CATEG_COD)) = 'DONATE' then 'Donations' else RTRIM(LTRIM(LINE.CATEG_COD)) end as CATEG_COD,
    RTRIM(LTRIM(LINE.SUBCAT_COD)) as SUBCAT_COD,
    RTRIM(LTRIM(LINE.DESCR)) as DESCR,
    case when RTRIM(LTRIM(LINE.CATEG_COD)) = 'DONATE' then 'Donations' else 'Merchandise Sales' end as SUMMARY_CATEGORY,
  -- get Sale line metrics
   count(case LINE.LIN_TYP when 'S' then 1 else 0 end) as Num_Tickets,
   sum(case LINE.LIN_TYP when 'S' then LINE.QTY_SOLD else 0 end) as QTY,
   sum(case LINE.LIN_TYP when 'S' then LINE.GROSS_EXT_PRC else 0 end) as Amount,
   -- get Return line metrics
   count(case LINE.LIN_TYP when 'R' then 1 else 0 end) as Return_Num_Tickets,
   sum(case LINE.LIN_TYP when 'R' then LINE.QTY_SOLD else 0 end) as Return_QTY,
   sum(case LINE.LIN_TYP when 'R' then LINE.GROSS_EXT_PRC else 0 end) as Return_Amount


from dbo.PS_TKT_HIST_LIN LINE
where 
--TICKET.DOC_ID=LINE.DOC_ID and
--(TICKET.STA_ID='21' OR TICKET.STA_ID='24' OR TICKET.STA_ID='25' OR TICKET.STA_ID='27' OR TICKET.STA_ID='28' OR TICKET.STA_ID='MOBILE4' OR TICKET.STA_ID='MOBILE5' OR 
--TICKET.STA_ID='MOBILE6' OR TICKET.STA_ID='VC-1' OR TICKET.STA_ID='VC-2' OR TICKET.STA_ID='VC-3' OR TICKET.STA_ID='VC-4' or TICKET.STA_ID='VC-5' OR TICKET.STA_ID='VC-6'
--OR TICKET.STA_ID='VC MGR 1' OR TICKET.STA_ID='VC MGR 2' OR TICKET.STA_ID='RETURNS') and
--TICKET.STA_ID in (21,24,25,27,28,'MOBILE4', 'MOBILE5', 'MOBILE6') and
--TICKET.STA_ID not in ('MOBILE1','MOBILE2','MOBILE3') and
--TICKET.STA_ID not in (22,23,26,'MOBILE1','MOBILE3','MOBILE2', 'MOBILE4', 'MOBILE5', 'MOBILE6') and
	LINE.STR_ID in ('2','5','7') and
 CONVERT(VARCHAR(10), LINE.BUS_DAT, 112) > dateadd(d,-7,?)

group by
	LINE.ITEM_NO,
    CONVERT(VARCHAR(10), LINE.BUS_DAT, 112),
    RTRIM(LTRIM(LINE.CATEG_COD)),
    RTRIM(LTRIM(LINE.SUBCAT_COD)),
    RTRIM(LTRIM(LINE.DESCR))
order by 1,2,5

-- ===== STEP: CounterPoint - Sales 2 [TableInput] conn=Counterpoint =====
select
LINE.ITEM_NO,
CONVERT(VARCHAR(10), LINE.BUS_DAT, 112) AS key_date,

1001 as key_facility,
    case when RTRIM(LTRIM(LINE.CATEG_COD)) = 'DONATE' then 'Donations' else RTRIM(LTRIM(LINE.CATEG_COD)) end as CATEG_COD,
    RTRIM(LTRIM(LINE.SUBCAT_COD)) as SUBCAT_COD,
    --RTRIM(LTRIM(LINE.DESCR)) as DESCR,
    case when RTRIM(LTRIM(LINE.CATEG_COD)) = 'DONATE' then 'Donations'else 'Merchandise Sales' end as SUMMARY_CATEGORY,
    -- get Sale line metrics
   count(case LINE.LIN_TYP when 'S' then 1 else 0 end) as Num_Tickets,
   sum(case LINE.LIN_TYP when 'S' then LINE.QTY_SOLD else 0 end) as QTY,
   sum(case LINE.LIN_TYP when 'S' then LINE.EXT_PRC else 0 end) as Amount,
   -- get Return line metrics
   count(case LINE.LIN_TYP when 'R' then 1 else 0 end) as Return_Num_Tickets,
   sum(case LINE.LIN_TYP when 'R' then LINE.QTY_SOLD else 0 end) as Return_QTY,
   sum(case LINE.LIN_TYP when 'R' then LINE.EXT_PRC else 0 end) as Return_Amount
from 
    dbo.PS_TKT_HIST_LIN LINE
where 
 -- TICKET.DOC_ID=LINE.DOC_ID and
--(TICKET.STA_ID = '22' OR TICKET.STA_ID='23' OR TICKET.STA_ID='26' OR TICKET.STA_ID='MOBILE1'  OR TICKET.STA_ID='MOBILE2' OR 
--TICKET.STA_ID='MOBILE3' OR TICKET.STA_ID='PS-2' OR TICKET.STA_ID='PS-3' OR TICKET.STA_ID='PS-1' OR TICKET.STA_ID='PS MGR 1'
--OR TICKET.STA_ID='PS MGR 2' OR TICKET.STA_ID='RETURNS') and 
--TICKET.STA_ID in (22,23,26,'MOBILE1','MOBILE3','MOBILE2') and
--TICKET.STA_ID not in ('MOBILE4','MOBILE5','MOBILE6') and 
--TICKET.STA_ID not  in (21,24,25,27,28,'MOBILE1','MOBILE3','MOBILE2', 'MOBILE4', 'MOBILE5', 'MOBILE6') and
LINE.STR_ID in ('1','4','6','8') and 
LINE.DESCR not like '%shipping%' and
CONVERT(VARCHAR(10), LINE.BUS_DAT, 112) >= dateadd(d,-3,?)



group by
	LINE.ITEM_NO,
    CONVERT(VARCHAR(10), LINE.BUS_DAT, 112),
    RTRIM(LTRIM(LINE.CATEG_COD)),
    RTRIM(LTRIM(LINE.SUBCAT_COD))
    --,RTRIM(LTRIM(LINE.DESCR))
	
        order by 2,1,5

-- ===== STEP: CounterPoint - Sales 3 [TableInput] conn=Counterpoint =====
SELECT
	LINE.ITEM_NO,
	CONVERT(VARCHAR(10), LINE.BUS_DAT, 112) AS key_date,
	1003 as key_facility,
	case when RTRIM(LTRIM(LINE.CATEG_COD)) = 'DONATE' then 'Donations' else RTRIM(LTRIM(LINE.CATEG_COD)) end as CATEG_COD,
	RTRIM(LTRIM(LINE.SUBCAT_COD)) as SUBCAT_COD,
	--RTRIM(LTRIM(LINE.DESCR)) as DESCR,
	case when RTRIM(LTRIM(LINE.CATEG_COD)) = 'DONATE' then 'Donations' else 'Merchandise Sales' end as SUMMARY_CATEGORY,
	-- get Sale line metrics
	count(case LINE.LIN_TYP when 'S' then 1 else 0 end) as Num_Tickets,
	sum(case LINE.LIN_TYP when 'S' then LINE.QTY_SOLD else 0 end) as QTY,
	SUM(CASE LINE.LIN_TYP WHEN 'S' THEN CASE WHEN LINE.ITEM_NO IN ('200933','201229') THEN 0 ELSE LINE.EXT_PRC END ELSE 0 END) AS Amount,
	sum(case LINE.LIN_TYP when 'S' then LINE.EXT_COST else 0 end) as Cost,
	-- get Return line metrics
	count(case LINE.LIN_TYP when 'R' then 1 else 0 end) as Return_Num_Tickets,
	sum(case LINE.LIN_TYP when 'R' then LINE.QTY_SOLD else 0 end) as Return_QTY,
	sum(case LINE.LIN_TYP when 'R' then LINE.EXT_PRC else 0 end) as Return_Amount
FROM 
    dbo.PS_TKT_HIST_LIN (NOLOCK) LINE
WHERE 
	(LINE.STR_ID IN ('8','9','10') OR (LINE.STR_ID = '14' AND item_no = '201205'))
AND LINE.DESCR NOT LIKE '%shipping%' 
AND LINE.BUS_DAT >= DATEADD(d,-5,?) 
GROUP BY
	LINE.ITEM_NO,
	CONVERT(VARCHAR(10), LINE.BUS_DAT, 112),
	RTRIM(LTRIM(LINE.CATEG_COD)),
	RTRIM(LTRIM(LINE.SUBCAT_COD))
ORDER BY 2,1,5

-- ===== STEP: CounterPoint - Sales 4 [TableInput] conn=Counterpoint =====
SELECT
	LINE.ITEM_NO,
	CONVERT(VARCHAR(10), LINE.BUS_DAT, 112) AS key_date,
	CASE WHEN LINE.ITEM_NO = '201114' THEN 1040 
	     WHEN LINE.ITEM_NO = '201197' THEN 1060 
		 WHEN LINE.ITEM_NO = '101504' THEN 1070
		 WHEN LINE.ITEM_NO IN ('100564', '100565', '100566', '100567', '100568', '100569') THEN 1080 
		 ELSE 1020 
	END AS key_facility,
	CASE WHEN RTRIM(LTRIM(LINE.CATEG_COD)) = 'DONATE' THEN 'Donations' ELSE RTRIM(LTRIM(LINE.CATEG_COD)) END AS CATEG_COD,
	RTRIM(LTRIM(LINE.SUBCAT_COD)) AS SUBCAT_COD,
	CASE WHEN RTRIM(LTRIM(LINE.CATEG_COD)) = 'DONATE' THEN 'Donations' ELSE 'Merchandise Sales' END AS SUMMARY_CATEGORY,
	-- get Sale line metrics
	COUNT(CASE LINE.LIN_TYP WHEN 'S' THEN 1 ELSE 0 END) AS NUM_TICKETS,
	SUM(CASE LINE.LIN_TYP WHEN 'S' THEN LINE.QTY_SOLD ELSE 0 END) AS QTY,
	SUM(CASE LINE.LIN_TYP WHEN 'S' THEN CASE WHEN LINE.ITEM_NO IN ('200933','201229') THEN 0 ELSE LINE.EXT_PRC END ELSE 0 END) AS Amount,
	SUM(CASE LINE.LIN_TYP WHEN 'S' THEN LINE.EXT_COST ELSE 0 END) AS Cost,
	-- GET RETURN LINE METRICS
	COUNT(CASE LINE.LIN_TYP WHEN 'R' THEN 1 ELSE 0 END) AS Return_Num_Tickets,
	SUM(CASE LINE.LIN_TYP WHEN 'R' THEN LINE.QTY_SOLD ELSE 0 END) AS Return_QTY,
	SUM(CASE LINE.LIN_TYP WHEN 'R' THEN LINE.EXT_PRC ELSE 0 END) AS Return_Amount
FROM 
    dbo.PS_TKT_HIST_LIN (NOLOCK) LINE 
WHERE 
	LINE.STR_ID IN ('11','12','13','14') 
	AND LINE.DESCR NOT LIKE '%shipping%' 
	AND LINE.BUS_DAT >= DATEADD(d,-1,?)
	AND LINE.ITEM_NO <> '201205'
GROUP BY
	LINE.ITEM_NO,
    CONVERT(VARCHAR(10), LINE.BUS_DAT, 112),
    RTRIM(LTRIM(LINE.CATEG_COD)),
    RTRIM(LTRIM(LINE.SUBCAT_COD))
ORDER BY key_date,ITEM_NO,SUBCAT_COD

-- ===== STEP: CounterPoint - Sales 5 [TableInput] conn=Counterpoint =====
SELECT
	LINE.ITEM_NO,
	CONVERT(VARCHAR(10), LINE.BUS_DAT, 112) AS key_date,
	1234 AS key_facility,
	CASE WHEN (RTRIM(LTRIM(LINE.CATEG_COD)) = 'DONATE' or LINE.ITEM_NO = '7-00003') THEN 'Donations' ELSE RTRIM(LTRIM(LINE.CATEG_COD)) END AS CATEG_COD,
	RTRIM(LTRIM(LINE.SUBCAT_COD)) AS SUBCAT_COD,
	--RTRIM(LTRIM(LINE.DESCR)) as DESCR,
	CASE WHEN (RTRIM(LTRIM(LINE.CATEG_COD)) = 'DONATE' or LINE.ITEM_NO = '7-00003') THEN 'Donations' ELSE 'Merchandise Sales' END AS SUMMARY_CATEGORY,
	-- get Sale line metrics
	COUNT(CASE LINE.LIN_TYP WHEN 'S' THEN 1 ELSE 0 END) AS Num_Tickets,
	SUM(CASE LINE.LIN_TYP WHEN 'S' THEN LINE.QTY_SOLD ELSE 0 END) AS QTY,
	SUM(CASE LINE.LIN_TYP WHEN 'S' THEN LINE.EXT_PRC ELSE 0 END) AS Amount,
	SUM(CASE LINE.LIN_TYP WHEN 'S' THEN LINE.EXT_COST ELSE 0 END) AS Cost,
	-- get Return line metrics
	COUNT(CASE LINE.LIN_TYP WHEN 'R' THEN 1 ELSE 0 END) AS Return_Num_Tickets,
	SUM(CASE LINE.LIN_TYP WHEN 'R' THEN LINE.QTY_SOLD ELSE 0 END) AS Return_QTY,
	SUM(CASE LINE.LIN_TYP WHEN 'R' THEN LINE.EXT_PRC ELSE 0 END) AS Return_Amount
FROM 
    dbo.PS_TKT_HIST_LIN LINE (NOLOCK)
WHERE 
    LINE.STR_ID IN ('3')
AND LINE.BUS_DAT >= '20170701'
AND LINE.DESCR NOT LIKE '%shipping%'   
GROUP BY
	LINE.ITEM_NO,
    CONVERT(VARCHAR(10), LINE.BUS_DAT, 112),
    RTRIM(LTRIM(LINE.CATEG_COD)),
    RTRIM(LTRIM(LINE.SUBCAT_COD))
    --RTRIM(LTRIM(LINE.DESCR))
ORDER BY 2,1,5

-- ===== STEP: CounterPoint - Sales 6 [TableInput] conn=Counterpoint =====
SELECT
	LINE.ITEM_NO,
	CONVERT(VARCHAR(10), LINE.BUS_DAT, 112) AS key_date,
	1030 AS key_facility,
	CASE WHEN RTRIM(LTRIM(LINE.CATEG_COD)) = 'DONATE' THEN 'Donations' ELSE RTRIM(LTRIM(LINE.CATEG_COD)) END AS CATEG_COD,
	RTRIM(LTRIM(LINE.SUBCAT_COD)) AS SUBCAT_COD,
	--RTRIM(LTRIM(LINE.DESCR)) AS DESCR,
	CASE WHEN RTRIM(LTRIM(LINE.CATEG_COD)) = 'DONATE' THEN 'Donations' ELSE 'Merchandise Sales' END AS SUMMARY_CATEGORY,
	-- get Sale line metrics
	COUNT(CASE LINE.LIN_TYP WHEN 'S' THEN 1 ELSE 0 END) AS Num_Tickets,
	SUM(CASE LINE.LIN_TYP WHEN 'S' THEN LINE.QTY_SOLD ELSE 0 END) AS QTY,
	SUM(CASE LINE.LIN_TYP WHEN 'S' THEN LINE.EXT_PRC ELSE 0 END) AS Amount,
	SUM(CASE LINE.LIN_TYP WHEN 'S' THEN LINE.EXT_COST ELSE 0 END) AS Cost,
	-- get Return line metrics
	count(CASE LINE.LIN_TYP WHEN 'R' THEN 1 ELSE 0 END) AS Return_Num_Tickets,
	SUM(CASE LINE.LIN_TYP WHEN 'R' THEN LINE.QTY_SOLD ELSE 0 END) AS Return_QTY,
	SUM(CASE LINE.LIN_TYP WHEN 'R' THEN LINE.EXT_PRC ELSE 0 END) AS Return_Amount
FROM 
    dbo.PS_TKT_HIST_LIN LINE
WHERE 
	LINE.STR_ID IN ('10') 
AND LINE.BUS_DAT >= '20191210'
AND LINE.DESCR NOT LIKE '%shipping%'
GROUP BY
	LINE.ITEM_NO,
    CONVERT(VARCHAR(10), LINE.BUS_DAT, 112),
    RTRIM(LTRIM(LINE.CATEG_COD)),
    RTRIM(LTRIM(LINE.SUBCAT_COD))
    --RTRIM(LTRIM(LINE.DESCR))
ORDER BY 2,1,5

-- ===== STEP: Get Start Date [TableInput] conn=911DW =====
SELECT
DATE_FORMAT(run_date_retail_start, '%Y%m%d' )
FROM run_date_retail_start

-- ===== STEP: Get Start Date 2 [TableInput] conn=911DW =====
SELECT
DATE_FORMAT(run_date_retail_start, '%Y%m%d' )
FROM run_date_retail_start

-- ===== STEP: Get Start Date 3 [TableInput] conn=911DW =====
SELECT
DATE_FORMAT(run_date_retail_start, '%Y%m%d' )
FROM run_date_retail_start

-- ===== STEP: Get Start Date 4 [TableInput] conn=911DW =====
SELECT
DATE_FORMAT(run_date_retail_start, '%Y%m%d' )
FROM run_date_retail_start

-- ===== STEP: CounterPoint - Sales 7 [TableInput] conn=Counterpoint =====
SELECT
	LINE.ITEM_NO,
	CONVERT(VARCHAR(10), LINE.BUS_DAT, 112) AS key_date,
	4007 as key_facility,
	CASE WHEN RTRIM(LTRIM(LINE.CATEG_COD)) = 'DONATE' THEN 'Donations' ELSE RTRIM(LTRIM(LINE.CATEG_COD)) END AS CATEG_COD,
	RTRIM(LTRIM(LINE.SUBCAT_COD)) AS SUBCAT_COD,
	CASE WHEN RTRIM(LTRIM(LINE.CATEG_COD)) = 'DONATE' THEN 'Donations' ELSE 'Merchandise Sales' END AS SUMMARY_CATEGORY,
	-- get Sale line metrics
	COUNT(CASE LINE.LIN_TYP WHEN 'S' THEN 1 ELSE 0 END) AS Num_Tickets,
	SUM(CASE LINE.LIN_TYP WHEN 'S' THEN LINE.QTY_SOLD ELSE 0 END) AS QTY,
	SUM(CASE LINE.LIN_TYP WHEN 'S' THEN CASE WHEN LINE.ITEM_NO = '200933' THEN 0 ELSE LINE.EXT_PRC END ELSE 0 END) AS Amount,
	SUM(CASE LINE.LIN_TYP WHEN 'S' THEN LINE.EXT_COST ELSE 0 END) AS Cost,
	-- get Return line metrics
	COUNT(CASE LINE.LIN_TYP WHEN 'R' THEN 1 ELSE 0 END) AS Return_Num_Tickets,
	SUM(CASE LINE.LIN_TYP WHEN 'R' THEN LINE.QTY_SOLD ELSE 0 END) AS Return_QTY,
	SUM(CASE LINE.LIN_TYP WHEN 'R' THEN LINE.EXT_PRC ELSE 0 END) AS Return_Amount
FROM 
    dbo.PS_TKT_HIST_LIN LINE (NOLOCK)
WHERE 
	LINE.STR_ID IN ('1') 
AND LINE.DESCR NOT LIKE '%shipping%'
AND LINE.BUS_DAT >= DATEADD(d,-5,?)
GROUP BY
	LINE.ITEM_NO,
    CONVERT(VARCHAR(10), LINE.BUS_DAT, 112),
    RTRIM(LTRIM(LINE.CATEG_COD)),
    RTRIM(LTRIM(LINE.SUBCAT_COD))
ORDER BY key_date, LINE.ITEM_NO, SUBCAT_COD

-- ===== STEP: Get Start Date 7 [TableInput] conn=911DW =====
SELECT
DATE_FORMAT(run_date_retail_start, '%Y%m%d' )
FROM run_date_retail_start