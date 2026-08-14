-- TRANSFORMATION: t_set_hold_date_retail
-- DESC: Set the date that the next run will start

-- WRITES: 911DW:.run_date_retail_hold (TableOutput)


-- ===== STEP: CounterPoint - max(TKT_DT) [TableInput] conn=Counterpoint =====
SELECT DATEADD(day, -1, max(TKT_DT)) as hold_date
from dbo.PS_TKT_HIST