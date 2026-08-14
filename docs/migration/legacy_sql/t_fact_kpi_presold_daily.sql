-- TRANSFORMATION: t_fact_kpi_presold_daily
-- DESC: 

-- WRITES: 911DW:.fact_kpi_presold (InsertUpdate)


-- ===== STEP: Items [TableInput] conn=Gateway Prod =====
DECLARE @NextMonth DATETIME
	SELECT @NextMonth = DATEADD(MONTH, 1, GETDATE())

	
	SELECT
			CAST(FORMAT(GETDATE(),'yyyyMMdd') AS INT)		AS 'key_date'
		   ,'Seven Day Pre-Sold'							AS 'time_interval'
		   ,SUM(ISNULL(vE.totalCapacity,0))-SUM(ISNULL(vE.available,0)) AS 'number_presold'
		   ,1	AS 'order_by'
		
	FROM report.vEvent (NOLOCK) vE	LEFT OUTER	JOIN report.vAttribute(NOLOCK) vA ON vE.avgID=vA.avgID
	WHERE
		vE.startDateTime >= DATEADD(dd,DATEDIFF(dd,0,GETDATE()+1),0)
	AND vE.startDateTime < DATEADD(dd,DATEDIFF(dd,0,GETDATE()+9),0)
	AND		(
							vE.eventTypeID	=	92
					OR		vE.eventTypeID	=	71
					OR		vE.eventTypeID	=	143
						AND	vE.resourceID	=	138
			)
		AND	vE.eventName NOT LIKE 'CLOSED%'
		AND	vE.eventName NOT LIKE 'N/A%'
		AND	vE.eventName NOT LIKE 'Snow Closure%'
	UNION
	SELECT
			CAST(FORMAT(GETDATE(),'yyyyMMdd') AS INT) as 'key_date'
		   ,'30 Day Pre-Sold'	AS 'time_interval'
		   ,SUM(ISNULL(vE.totalCapacity,0))-SUM(ISNULL(vE.available,0)) As 'number_presold'
		   ,2	AS 'order_by'
		
	FROM report.vEvent (NOLOCK) vE	LEFT OUTER	JOIN report.vAttribute(NOLOCK) vA ON vE.avgID=vA.avgID
	WHERE
		vE.startDateTime >= DATEADD(dd,DATEDIFF(dd,0,GETDATE()+1),0)
	AND vE.startDateTime <  DATEADD(dd,DATEDIFF(dd,0,GETDATE()+33),0)
	AND		(
							vE.eventTypeID	=	92
					OR		vE.eventTypeID	=	71
					OR		vE.eventTypeID	=	143
						AND	vE.resourceID	=	138
			)
	AND	vE.eventName NOT LIKE 'CLOSED%'
	AND	vE.eventName NOT LIKE 'N/A%'
	AND	vE.eventName NOT LIKE 'Snow Closure%'
	UNION
	SELECT
			CAST(FORMAT(GETDATE(),'yyyyMMdd') AS INT)	AS 'key_date'
		   ,'Next Month Pre-Sold'						AS 'time_interval'
		   ,SUM(ISNULL(vE.totalCapacity,0))-SUM(ISNULL(vE.available,0)) AS 'number_presold'
		   ,3	AS 'order_by'
		
	FROM report.vEvent (NOLOCK) vE	LEFT OUTER	JOIN report.vAttribute(NOLOCK) vA ON vE.avgID=vA.avgID
	WHERE
		YEAR(vE.startDateTime) = YEAR(@NextMonth) AND MONTH(vE.startDateTime) = MONTH(@NextMonth) 

	AND		(
							vE.eventTypeID	=	92
					OR		vE.eventTypeID	=	71
					OR		vE.eventTypeID	=	143
						AND	vE.resourceID	=	138
			)
	AND	vE.eventName NOT LIKE 'CLOSED%'
	AND	vE.eventName NOT LIKE 'N/A%'
	AND	vE.eventName NOT LIKE 'Snow Closure%'