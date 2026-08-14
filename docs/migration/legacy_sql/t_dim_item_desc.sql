-- TRANSFORMATION: t_dim_item_desc
-- DESC: Retail Store Item Description

-- WRITES: 911DW:.dim_item_descr (InsertUpdate)


-- ===== STEP: Counterpoint - Description from IM_ITEM Table [TableInput] conn=Counterpoint =====
SELECT 
ITEM_NO,
DESCR,
 	BARCOD,
 	LST_COST,
	PRC_1,
'$'+ltrim(cast(round(LST_COST,2) as char)) as COST_STR,
'$'+ltrim(cast(round(PRC_1,2) as char)) as PRC_STR
 FROM  dbo.IM_ITEM
where CONVERT(VARCHAR(10),LST_MAINT_DT , 112) >= '20120730'