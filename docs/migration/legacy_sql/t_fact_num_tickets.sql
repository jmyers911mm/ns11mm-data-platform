-- TRANSFORMATION: t_fact_num_tickets
-- DESC: Passes Issued from Events Tables

-- WRITES: 911DW:.fact_num_tickets (InsertUpdate)
-- WRITES: 911DW:.fact_num_tickets (InsertUpdate)
-- WRITES: 911DW:.fact_num_tickets (InsertUpdate)
-- WRITES: 911DW:.fact_num_tickets (InsertUpdate)
-- WRITES: 911DW:.fact_num_tickets (InsertUpdate)
-- WRITES: 911DW:.fact_num_tickets (InsertUpdate)
-- WRITES: 911DW:.fact_num_tickets (InsertUpdate)
-- WRITES: 911DW:.fact_num_tickets (InsertUpdate)
-- WRITES: 911DW:.fact_num_tickets (InsertUpdate)
-- WRITES: 911DW:.fact_num_tickets (InsertUpdate)
-- WRITES: 911DW:.fact_num_tickets (InsertUpdate)


-- ===== STEP: Counterpoint - Num Tickets per day - Visitors Center [TableInput] conn=Counterpoint =====
select
CONVERT(VARCHAR(10), TICKET.TKT_DT, 112) AS key_date,
1002 as key_facility,
count(TICKET.TKT_NO) as Num_Tickets
from dbo.PS_TKT_HIST TICKET
where 
(TICKET.STA_ID='21' OR TICKET.STA_ID='24' OR TICKET.STA_ID='25' OR TICKET.STA_ID='27' OR TICKET.STA_ID='28'OR TICKET.STA_ID='VC-4' OR TICKET.STA_ID='VC-5' OR TICKET.STA_ID='VC-6' OR
TICKET.STA_ID='MOBILE10' OR
TICKET.STA_ID='MOBILE11' OR
TICKET.STA_ID='MOBILE12' OR TICKET.STA_ID='VC-1' OR TICKET.STA_ID='VC-2' OR TICKET.STA_ID='VC-3' OR TICKET.STA_ID='VC MGR 1' OR TICKET.STA_ID='VC MGR 2')

and CONVERT(VARCHAR(10), TICKET.TKT_DT, 112) > '20121028'
group by
    CONVERT(VARCHAR(10), TICKET.TKT_DT, 112)
order by 1,2

-- ===== STEP: Counterpoint - Num Tickets per day Atrium [TableInput] conn=Counterpoint =====
SELECT
	CONVERT(VARCHAR(10), TICKET.TKT_DT, 112) AS key_date,
	1030 as key_facility,
	COUNT(TICKET.TKT_NO) as Num_Tickets
FROM dbo.PS_TKT_HIST TICKET (NOLOCK)
WHERE TICKET.STR_ID IN ('10')
  AND TICKET.TKT_DT >= '20191210'
GROUP BY
    CONVERT(VARCHAR(10), TICKET.TKT_DT, 112)
ORDER BY 1,2

-- ===== STEP: Counterpoint - Num Tickets per day Ecommerce [TableInput] conn=Counterpoint =====
SELECT
	CONVERT(VARCHAR(10), TICKET.TKT_DT, 112) AS key_date,
	1234 AS key_facility,
	COUNT(TICKET.TKT_NO) AS Num_Tickets
FROM dbo.PS_TKT_HIST (NOLOCK) TICKET
WHERE TICKET.TKT_DT >= '20170701' 
  AND TICKET.STR_ID IN ('3')
GROUP BY
    CONVERT(VARCHAR(10), TICKET.TKT_DT, 112)
ORDER BY 1,2

-- ===== STEP: Counterpoint - Num Tickets per day Memorial Carts [TableInput] conn=Counterpoint =====
SELECT
	CONVERT(VARCHAR(10), TICKET.TKT_DT, 112) AS key_date,
	1020 AS key_facility,
	COUNT(TICKET.TKT_NO) AS Num_Tickets
FROM dbo.PS_TKT_HIST TICKET (NOLOCK)
WHERE TICKET.STR_ID IN ('11', '12','13') 
  AND TICKET.TKT_DT >= '20150525' 
  AND doc_id NOT IN
	(
		SELECT doc_id
		FROM  dbo.PS_TKT_HIST_LIN LINE (NOLOCK)
		WHERE LINE.STR_ID IN ('11','12','13') 
		  AND LINE.DESCR NOT LIKE '%shipping%'
		  AND  LINE.BUS_DAT  >= '20230904' AND LINE.ITEM_NO IN ('200933','201229','201114','201197')
	)
GROUP BY CONVERT(VARCHAR(10), TICKET.TKT_DT, 112)
ORDER BY key_date,key_facility

-- ===== STEP: Counterpoint - Num Tickets per day Museum Store [TableInput] conn=Counterpoint =====
SELECT
	CONVERT(VARCHAR(10), TICKET.TKT_DT, 112) AS key_date,
	1003 AS key_facility,
	COUNT(TICKET.TKT_NO) as Num_Tickets
FROM dbo.PS_TKT_HIST TICKET (NOLOCK)
WHERE 
	TICKET.STR_ID IN ('8','9','10') 
OR (
		TICKET.STR_ID = '14' 
	AND TICKET.doc_id IN
		(
			SELECT doc_id
			FROM  dbo.PS_TKT_HIST_LIN LINE (NOLOCK)
			WHERE LINE.STR_ID IN ('14') 
			  AND LINE.BUS_DAT > '20240101' AND LINE.ITEM_NO IN ('201205')
		)
   )
AND TICKET.TKT_DT > '20170423'
GROUP BY CONVERT(VARCHAR(10), TICKET.TKT_DT, 112)
ORDER BY 1,2

-- ===== STEP: Counterpoint - Num Tickets per day Preview [TableInput] conn=Counterpoint =====
select
CONVERT(VARCHAR(10), TICKET.TKT_DT, 112) AS key_date,
1001 as key_facility,
count(TICKET.TKT_NO) as Num_Tickets
from dbo.PS_TKT_HIST TICKET
where 
--(TICKET.STA_ID='22' OR TICKET.STA_ID='23' OR TICKET.STA_ID='26' OR TICKET.STA_ID='MOBILE1' OR TICKET.STA_ID='MOBILE2' OR 
--TICKET.STA_ID='MOBILE3' OR TICKET.STA_ID='PS-2' OR TICKET.STA_ID='PS-3' OR TICKET.STA_ID='PS-1' OR TICKET.STA_ID='PS MGR 1' OR TICKET.STA_ID='PS MGR 2' OR
--TICKET.STA_ID='MOBILE7' OR
--TICKET.STA_ID='MOBILE8' OR
--TICKET.STA_ID='MOBILE9' OR TICKET.STA_ID = 'MOBILE13' OR TICKET.STA_ID='MOBILE14' OR TICKET.STA_ID='MOBILE17' OR TICKET.STA_ID='MOBILE18' OR TICKET.STA_ID='MOBILE19'
--or TICKET.STA_ID = 'MOBILE4' or TICKET.STA_ID = 'MOBILE5' or TICKET.STA_ID = 'MOBILE6' or TICKET.STA_ID = 'PS MGR 6' or TICKET.STA_ID = 'RETURNS' )
TICKET.STR_ID IN ('1','4','6','8')
and CONVERT(VARCHAR(10), TICKET.TKT_DT, 112) >= '20140709'
group by
    CONVERT(VARCHAR(10), TICKET.TKT_DT, 112)
order by 1,2

-- ===== STEP: Counterpoint - Num Tickets per day Cafe1 [TableInput] conn=Counterpoint =====
SELECT
	CONVERT(VARCHAR(10), TICKET.TKT_DT, 112) AS key_date,
	4007 AS key_facility,
	COUNT(TICKET.TKT_NO) AS Num_Tickets
FROM dbo.PS_TKT_HIST TICKET (NOLOCK)
WHERE TICKET.TKT_DT >= '20221128'
  AND TICKET.STR_ID = '1'
GROUP BY
    CONVERT(VARCHAR(10), TICKET.TKT_DT, 112)
ORDER BY key_date,key_facility

-- ===== STEP: Counterpoint - Num Tickets per day MAG [TableInput] conn=Counterpoint =====
SELECT
	CONVERT(VARCHAR(10), TICKET.TKT_DT, 112) AS key_date,
	1040 AS key_facility,
	COUNT(TICKET.TKT_NO) AS Num_Tickets
FROM dbo.PS_TKT_HIST TICKET (NOLOCK)
WHERE TICKET.STR_ID in ('11', '12','13','14') 
  AND TICKET.TKT_DT >= '20230904' 
  AND doc_id IN
	(
		SELECT doc_id
		FROM dbo.PS_TKT_HIST_LIN LINE (NOLOCK)
		WHERE LINE.STR_ID IN ('11','12','13', '14') 
		  AND LINE.DESCR NOT LIKE '%shipping%'
		  AND LINE.BUS_DAT >= '20230904' AND LINE.ITEM_NO = '201114'
	)
GROUP BY CONVERT(VARCHAR(10), TICKET.TKT_DT, 112)
ORDER BY key_date,key_facility

-- ===== STEP: Counterpoint - Num Tickets per day MUS AG [TableInput] conn=Counterpoint =====
SELECT
	CONVERT(VARCHAR(10), TICKET.TKT_DT, 112) AS key_date,
	1060 AS key_facility,
	COUNT(TICKET.TKT_NO) AS Num_Tickets
FROM dbo.PS_TKT_HIST TICKET (NOLOCK)
WHERE TICKET.STR_ID in ('11', '12','13','14') 
  AND TICKET.TKT_DT >= '20240116' 
  AND doc_id IN
	(
		SELECT doc_id
		FROM dbo.PS_TKT_HIST_LIN LINE (NOLOCK)
		WHERE LINE.STR_ID IN ('11','12','13', '14') 
		  AND LINE.DESCR NOT LIKE '%shipping%'
		  AND LINE.BUS_DAT  >= '20240116' AND LINE.ITEM_NO = '201197'
	)
GROUP BY CONVERT(VARCHAR(10), TICKET.TKT_DT, 112)
ORDER BY key_date,key_facility

-- ===== STEP: Counterpoint - Num Tickets per day MGT [TableInput] conn=Counterpoint =====
SELECT
	CONVERT(VARCHAR(10), TICKET.TKT_DT, 112) AS key_date,
	1070 AS key_facility,
	COUNT(TICKET.TKT_NO) AS Num_Tickets
FROM dbo.PS_TKT_HIST TICKET (NOLOCK)
WHERE TICKET.STR_ID IN ('14') 
  AND TICKET.TKT_DT >= '20240121' 
  AND doc_id IN
	(
		SELECT doc_id
		FROM dbo.PS_TKT_HIST_LIN LINE (NOLOCK)
		WHERE LINE.STR_ID IN ('14') 
			AND LINE.DESCR NOT LIKE '%shipping%'
			AND LINE.BUS_DAT  >= '20240121' AND LINE.ITEM_NO = '101504'
	)
GROUP BY CONVERT(VARCHAR(10), TICKET.TKT_DT, 112)
ORDER BY key_date,key_facility

-- ===== STEP: Counterpoint - Num Tickets per day MEMBERSHIPS [TableInput] conn=Counterpoint =====
SELECT
	CONVERT(VARCHAR(10), TICKET.TKT_DT, 112) AS key_date,
	1080 AS key_facility,
	COUNT(TICKET.TKT_NO) AS Num_Tickets
FROM dbo.PS_TKT_HIST TICKET (NOLOCK)
WHERE TICKET.STR_ID in ('14') 
  AND TICKET.TKT_DT >= '20231129' 
  AND doc_id IN
	(
		SELECT doc_id
		FROM dbo.PS_TKT_HIST_LIN LINE (NOLOCK)
		WHERE LINE.STR_ID IN ('14') 
		  AND LINE.DESCR NOT LIKE '%shipping%'
		  AND LINE.BUS_DAT  >= '20231129' AND LINE.ITEM_NO IN ('100564', '100565', '100566', '100567', '100568', '100569')
	)
GROUP BY CONVERT(VARCHAR(10), TICKET.TKT_DT, 112)
ORDER BY key_date,key_facility