-- TRANSFORMATION: t_fact_cogs
-- DESC: Retail Fact

-- WRITES: 911DW:.fact_cogs (InsertUpdate)
-- WRITES: 911DW:.fact_cogs (InsertUpdate)
-- WRITES: 911DW:.fact_cogs (InsertUpdate)
-- WRITES: 911DW:.fact_cogs (InsertUpdate)
-- WRITES: 911DW:.fact_cogs (InsertUpdate)
-- WRITES: 911DW:.fact_cogs (InsertUpdate)
-- WRITES: 911DW:.fact_cogs (InsertUpdate)
-- WRITES: 911DW:.fact_cogs (InsertUpdate)
-- WRITES: 911DW:.fact_cogs (InsertUpdate)
-- WRITES: 911DW:.fact_cogs (InsertUpdate)
-- WRITES: 911DW:.fact_cogs (InsertUpdate)


-- ===== STEP: CounterPoint - Cost and Sales [TableInput] conn=Counterpoint =====
select key_date, 1002 as key_facility, sum(Total_Cost) as Cost, SUM(Sales_Amount) as Sales from 
(
select LINE.ITEM_NO,
CONVERT(VARCHAR(10), TICKET.BUS_DAT, 112) as key_date, SUM( LINE.EXT_COST )as Total_Cost, SUM(LINE.GROSS_EXT_PRC) as Sales_Amount
from dbo.PS_TKT_HIST_LIN LINE, dbo.PS_TKT_HIST TICKET
where 
 TICKET.DOC_ID=LINE.DOC_ID 
 and
 (TICKET.STA_ID='21' OR TICKET.STA_ID='24' OR TICKET.STA_ID='25' OR TICKET.STA_ID='27' OR TICKET.STA_ID='28' 
 OR TICKET.STA_ID='VC-1' OR TICKET.STA_ID='VC-2' OR TICKET.STA_ID='VC-3' OR TICKET.STA_ID='VC-4' or TICKET.STA_ID='VC-5' OR TICKET.STA_ID='VC-6'
OR TICKET.STA_ID='VC MGR 1' OR TICKET.STA_ID='VC MGR 2' OR TICKET.STA_ID='RETURNS'
) 
--LINE.STR_ID in ('2','5') 
--and LINE.ITEM_NO not in ('100443')
--and CONVERT(VARCHAR(10), TICKET.BUS_DAT, 112) > '20130610'

group by LINE.ITEM_NO,
LINE.EXT_COST,  CONVERT(VARCHAR(10), TICKET.BUS_DAT, 112)
)
as T
group by key_date
order by key_date

-- ===== STEP: CounterPoint - Cost and Sales 2 [TableInput] conn=Counterpoint =====
select key_date, 1001 as key_facility, sum(Total_Cost) as Cost, SUM(Sales_Amount) as Sales from 
(
select LINE.ITEM_NO,
CONVERT(VARCHAR(10), TICKET.BUS_DAT, 112) as key_date, SUM( LINE.EXT_COST )as Total_Cost, SUM(LINE.GROSS_EXT_PRC) as Sales_Amount
from  dbo.VI_PS_TKT_HIST TICKET inner join dbo.VI_PS_TKT_HIST_LIN LINE
on 
 TICKET.DOC_ID=LINE.DOC_ID and TICKET.BUS_DAT = LINE.BUS_DAT
where TICKET.TKT_TYP = 'T' and LINE.LIN_TYP <> 'U'
--(TICKET.STA_ID = '22' OR TICKET.STA_ID='23' OR TICKET.STA_ID='26' OR TICKET.STA_ID='MOBILE1'  OR TICKET.STA_ID='MOBILE2' OR 
--TICKET.STA_ID='MOBILE3' OR TICKET.STA_ID='PS-2' OR TICKET.STA_ID='PS-3' OR TICKET.STA_ID='PS-1' OR TICKET.STA_ID='PS MGR 1'
 --OR TICKET.STA_ID='PS MGR 2' OR TICKET.STA_ID='RETURNS' OR TICKET.STA_ID='MOBILE13' OR TICKET.STA_ID='MOBILE14')
--and CONVERT(VARCHAR(10), TICKET.BUS_DAT, 112) >= '20140515' 
and CONVERT(VARCHAR(10), TICKET.BUS_DAT, 112) >= '20150601' 
and LINE.STR_ID in ('1','4','6','8') 
group by LINE.ITEM_NO,
LINE.EXT_COST,  CONVERT(VARCHAR(10), TICKET.BUS_DAT, 112)
)
as T
group by key_date
order by key_date

-- ===== STEP: CounterPoint - Cost and Sales 3 [TableInput] conn=Counterpoint =====
SELECT 
	key_date, 
	1003 AS key_facility, 
	SUM(Total_Cost) AS Cost, 
	SUM(Sales_Amount) AS Sales 
FROM 
(
SELECT
	LINE.ITEM_NO,
	CONVERT(VARCHAR(10), 
	TICKET.BUS_DAT, 112) AS key_date, 
	SUM(LINE.EXT_COST) AS Total_Cost, 
	SUM( CASE WHEN LINE.ITEM_NO IN ('200933','201229') THEN 0 ELSE LINE.GROSS_EXT_PRC END ) AS Sales_Amount
FROM dbo.VI_PS_TKT_HIST (NOLOCK) TICKET INNER JOIN dbo.VI_PS_TKT_HIST_LIN (NOLOCK) LINE ON 
										TICKET.DOC_ID=LINE.DOC_ID AND TICKET.BUS_DAT = LINE.BUS_DAT
WHERE 
	TICKET.TKT_TYP = 'T' 
AND LINE.LIN_TYP <> 'U'
AND (LINE.STR_ID IN ('8','9','10') OR (LINE.STR_ID = '14' AND item_no = '201205'))
AND TICKET.BUS_DAT >= '20170423'
GROUP BY 
LINE.ITEM_NO,
LINE.EXT_COST,  
CONVERT(VARCHAR(10), TICKET.BUS_DAT, 112)
)
AS T
GROUP BY key_date
ORDER BY key_date

-- ===== STEP: CounterPoint - Cost and Sales 4 [TableInput] conn=Counterpoint =====
SELECT 
	key_date, 
	1020 AS key_facility, 
	SUM(Total_Cost) AS Cost, 
	SUM(Sales_Amount) AS Sales 
FROM 
(
SELECT	LINE.ITEM_NO,
		CONVERT(VARCHAR(10), TICKET.BUS_DAT, 112) AS key_date, 
		SUM( LINE.EXT_COST ) AS Total_Cost, 
		SUM(LINE.GROSS_EXT_PRC) AS Sales_Amount
FROM dbo.VI_PS_TKT_HIST (NOLOCK) TICKET INNER JOIN 
	 dbo.VI_PS_TKT_HIST_LIN LINE (NOLOCK) ON TICKET.DOC_ID=LINE.DOC_ID and TICKET.BUS_DAT = LINE.BUS_DAT
WHERE TICKET.BUS_DAT >= '20150525'
	AND LINE.STR_ID IN ('11','12','13') 
	AND TICKET.TKT_TYP = 'T' AND LINE.LIN_TYP <> 'U'
	AND LINE.ITEM_NO NOT IN ('201114','201197','101504','200933','201229')
GROUP BY 
LINE.ITEM_NO,
LINE.EXT_COST,  
CONVERT(VARCHAR(10), TICKET.BUS_DAT, 112)
)
AS T
GROUP BY key_date
ORDER BY key_date

-- ===== STEP: CounterPoint - Cost and Sales 5 [TableInput] conn=Counterpoint =====
select key_date, 1234 as key_facility, sum(Total_Cost) as Cost, SUM(Sales_Amount) as Sales from 
(
select LINE.ITEM_NO,
CONVERT(VARCHAR(10), TICKET.BUS_DAT, 112) as key_date, SUM( LINE.EXT_COST )as Total_Cost, SUM(LINE.GROSS_EXT_PRC) as Sales_Amount
 from dbo.VI_PS_TKT_HIST TICKET inner join dbo.VI_PS_TKT_HIST_LIN LINE
on 
 TICKET.DOC_ID=LINE.DOC_ID and TICKET.BUS_DAT = LINE.BUS_DAT
where TICKET.TKT_TYP = 'T' and LINE.LIN_TYP <> 'U'
 and
LINE.STR_ID in ('3') 
and CONVERT(VARCHAR(10), TICKET.BUS_DAT, 112) >= '20170701'
group by LINE.ITEM_NO,
LINE.EXT_COST,  CONVERT(VARCHAR(10), TICKET.BUS_DAT, 112)
)
as T
group by key_date
order by key_date

-- ===== STEP: CounterPoint - Cost and Sales 6 [TableInput] conn=Counterpoint =====
select key_date, 1030 as key_facility, sum(Total_Cost) as Cost, SUM(Sales_Amount) as Sales from 
(
select LINE.ITEM_NO,
CONVERT(VARCHAR(10), TICKET.BUS_DAT, 112) as key_date, SUM( LINE.EXT_COST )as Total_Cost, SUM(LINE.GROSS_EXT_PRC) as Sales_Amount
 from dbo.VI_PS_TKT_HIST TICKET inner join dbo.VI_PS_TKT_HIST_LIN LINE
on 
 TICKET.DOC_ID=LINE.DOC_ID and TICKET.BUS_DAT = LINE.BUS_DAT
where TICKET.TKT_TYP = 'T' and LINE.LIN_TYP <> 'U'
 and
LINE.STR_ID in ('10') 
and CONVERT(VARCHAR(10), TICKET.BUS_DAT, 112) >= '20191210'
group by LINE.ITEM_NO,
LINE.EXT_COST,  CONVERT(VARCHAR(10), TICKET.BUS_DAT, 112)
)
as T
group by key_date
order by key_date

-- ===== STEP: CounterPoint - Cafe1 [TableInput] conn=Counterpoint =====
SELECT 
	key_date, 
	4007 AS key_facility, 
	SUM(Total_Cost) AS Cost, 
	SUM(Sales_Amount) AS Sales 
FROM 
(
	SELECT 
	    LINE.ITEM_NO,
		CONVERT(VARCHAR(10), 
		TICKET.BUS_DAT, 112) as key_date, 
		SUM( LINE.EXT_COST ) as Total_Cost, 
		SUM( CASE WHEN ITEM_NO = '200933' THEN 0 ELSE LINE.GROSS_EXT_PRC END ) as Sales_Amount
	FROM dbo.VI_PS_TKT_HIST TICKET (NOLOCK) INNER JOIN dbo.VI_PS_TKT_HIST_LIN LINE (NOLOCK) ON TICKET.DOC_ID = LINE.DOC_ID 
								                                                           AND TICKET.BUS_DAT = LINE.BUS_DAT
	WHERE  TICKET.TKT_TYP = 'T' 
	   AND LINE.STR_ID IN ('1') 
       AND LINE.LIN_TYP <> 'U'
       AND TICKET.BUS_DAT >= '20221128'
	GROUP BY 
		LINE.ITEM_NO,
		LINE.EXT_COST,  
		CONVERT(VARCHAR(10), TICKET.BUS_DAT, 112)
)
AS T
GROUP BY key_date
ORDER BY key_date

-- ===== STEP: CounterPoint - MAG [TableInput] conn=Counterpoint =====
SELECT 
	key_date, 
	1040 AS key_facility, 
	SUM(Total_Cost) AS Cost, 
	SUM(Sales_Amount) AS Sales 
FROM 
(
SELECT	LINE.ITEM_NO,
		CONVERT(VARCHAR(10), TICKET.BUS_DAT, 112) AS key_date, 
		SUM( LINE.EXT_COST ) AS Total_Cost, 
		SUM(LINE.GROSS_EXT_PRC) AS Sales_Amount
FROM dbo.VI_PS_TKT_HIST (NOLOCK) TICKET INNER JOIN 
	 dbo.VI_PS_TKT_HIST_LIN LINE (NOLOCK) ON TICKET.DOC_ID=LINE.DOC_ID and TICKET.BUS_DAT = LINE.BUS_DAT
WHERE TICKET.BUS_DAT >= '20230904' AND LINE.ITEM_NO = '201114'
  AND TICKET.TKT_TYP = 'T' AND LINE.LIN_TYP <> 'U'
  AND LINE.STR_ID IN ('11','12','13','14') 
GROUP BY LINE.ITEM_NO,
LINE.EXT_COST,  CONVERT(VARCHAR(10), TICKET.BUS_DAT, 112)
)
AS T
GROUP BY key_date
ORDER BY key_date

-- ===== STEP: CounterPoint - MUS AG [TableInput] conn=Counterpoint =====
SELECT 
	key_date, 
	1060 AS key_facility, 
	SUM(Total_Cost) AS Cost, 
	SUM(Sales_Amount) AS Sales 
FROM 
(
SELECT	LINE.ITEM_NO,
		CONVERT(VARCHAR(10), TICKET.BUS_DAT, 112) AS key_date, 
		SUM( LINE.EXT_COST ) AS Total_Cost, 
		SUM(LINE.GROSS_EXT_PRC) AS Sales_Amount
FROM dbo.VI_PS_TKT_HIST (NOLOCK) TICKET INNER JOIN 
	 dbo.VI_PS_TKT_HIST_LIN LINE (NOLOCK) ON TICKET.DOC_ID=LINE.DOC_ID and TICKET.BUS_DAT = LINE.BUS_DAT
WHERE TICKET.BUS_DAT >= '20240116' AND LINE.ITEM_NO = '201197'
  AND TICKET.TKT_TYP = 'T' AND LINE.LIN_TYP <> 'U'
  AND LINE.STR_ID IN ('11','12','13','14') 
GROUP BY LINE.ITEM_NO,
LINE.EXT_COST,  CONVERT(VARCHAR(10), TICKET.BUS_DAT, 112)
)
AS T
GROUP BY key_date
ORDER BY key_date

-- ===== STEP: CounterPoint - MTG [TableInput] conn=Counterpoint =====
SELECT 
	key_date, 
	1070 AS key_facility, 
	SUM(Total_Cost) AS Cost, 
	SUM(Sales_Amount) AS Sales 
FROM 
(
SELECT	LINE.ITEM_NO,
		CONVERT(VARCHAR(10), TICKET.BUS_DAT, 112) AS key_date, 
		SUM( LINE.EXT_COST ) AS Total_Cost, 
		SUM(LINE.GROSS_EXT_PRC) AS Sales_Amount
FROM dbo.VI_PS_TKT_HIST (NOLOCK) TICKET INNER JOIN 
	 dbo.VI_PS_TKT_HIST_LIN LINE (NOLOCK) ON TICKET.DOC_ID=LINE.DOC_ID and TICKET.BUS_DAT = LINE.BUS_DAT
WHERE LINE.STR_ID = '14'  
  AND LINE.ITEM_NO = '101504'
  AND TICKET.BUS_DAT >= '20240121'
  AND TICKET.TKT_TYP = 'T' AND LINE.LIN_TYP <> 'U'
GROUP BY LINE.ITEM_NO,
LINE.EXT_COST,  CONVERT(VARCHAR(10), TICKET.BUS_DAT, 112)
)
AS T
GROUP BY key_date
ORDER BY key_date

-- ===== STEP: CounterPoint - MEMBERSHIPS [TableInput] conn=Counterpoint =====
SELECT 
	key_date, 
	1080 AS key_facility, 
	SUM(Total_Cost) AS Cost, 
	SUM(Sales_Amount) AS Sales 
FROM 
(
SELECT	LINE.ITEM_NO,
		CONVERT(VARCHAR(10), TICKET.BUS_DAT, 112) AS key_date, 
		SUM( LINE.EXT_COST ) AS Total_Cost, 
		SUM(LINE.GROSS_EXT_PRC) AS Sales_Amount
FROM dbo.VI_PS_TKT_HIST (NOLOCK) TICKET INNER JOIN 
	 dbo.VI_PS_TKT_HIST_LIN LINE (NOLOCK) ON TICKET.DOC_ID=LINE.DOC_ID and TICKET.BUS_DAT = LINE.BUS_DAT
WHERE LINE.STR_ID = '14'
  AND TICKET.BUS_DAT >= '20240121'
  AND TICKET.TKT_TYP = 'T' AND LINE.LIN_TYP <> 'U' 
  AND LINE.ITEM_NO IN ('100564', '100565', '100566', '100567', '100568', '100569')
GROUP BY LINE.ITEM_NO,
LINE.EXT_COST,  CONVERT(VARCHAR(10), TICKET.BUS_DAT, 112)
)
AS T
GROUP BY key_date
ORDER BY key_date