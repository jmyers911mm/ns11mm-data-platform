-- TRANSFORMATION: t_dim_city_stub
-- DESC: 

-- WRITES: 911DW:.dim_city (InsertUpdate)


-- ===== STEP: Get cities from Google Fact [TableInput] conn=911DW =====
SELECT DISTINCT
city
FROM stage_visit_sess_page_track_etl