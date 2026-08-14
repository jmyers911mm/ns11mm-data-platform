-- TRANSFORMATION: t_set_next_run_date_retail
-- DESC: Set the date that the next run will start

-- WRITES: 911DW:.run_date_retail_start (TableOutput)


-- ===== STEP: run_date_retail_hold [TableInput] conn=911DW =====
SELECT
  run_date_retail_hold
FROM run_date_retail_hold