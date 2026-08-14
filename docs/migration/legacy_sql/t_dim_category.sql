-- TRANSFORMATION: t_dim_category
-- DESC: Retail Store Category Dimension

-- WRITES: 911DW:.dim_category (InsertUpdate)


-- ===== STEP: CounterPoint - CATEG_COD [TableInput] conn=Counterpoint =====
SELECT
  CATEG_COD
FROM dbo.PS_TKT_HIST_LIN
group by CATEG_COD