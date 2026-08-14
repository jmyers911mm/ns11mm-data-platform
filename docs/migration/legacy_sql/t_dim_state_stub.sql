-- TRANSFORMATION: t_dim_state_stub
-- DESC: 

-- WRITES: 911DW:.dim_state (InsertUpdate)


-- ===== STEP: Read Google Analytics Fact for Region (State) Codes [TableInput] conn=911DW =====
SELECT distinct
 f.region,s.state_code
FROM stage_visit_sess_page_track_etl f
inner join stage_state_code_etl s
 on f.region = s.state_name