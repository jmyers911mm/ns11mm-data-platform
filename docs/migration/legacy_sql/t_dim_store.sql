-- TRANSFORMATION: t_dim_store
-- DESC: Retail Store Dimension

-- WRITES: 911DW:.dim_store (InsertUpdate)


-- ===== STEP: CounterPoint - STR_ID and DESCR [TableInput] conn=Counterpoint =====
SELECT
  STR_ID
, DESCR
FROM dbo.PS_STR