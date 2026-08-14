-- TRANSFORMATION: t_dim_sub_category
-- DESC: Retail Store Sub Category Dimension

-- WRITES: 911DW:.dim_sub_category (InsertUpdate)


-- ===== STEP: CounterPoint - SUBCAT_COD [TableInput] conn=Counterpoint =====
SELECT
  SUBCAT_COD
FROM dbo.PS_TKT_HIST_LIN
group by SUBCAT_COD