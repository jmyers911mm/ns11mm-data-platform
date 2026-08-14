-- TRANSFORMATION: t_dim_country_stub
-- DESC: 

-- WRITES: 911DW:.dim_country (InsertUpdate)


-- ===== STEP: Read Google Analytics Fact for Countries [TableInput] conn=911DW =====
SELECT distinct
 s1.country,s2.country_iso_code 
FROM stage_geo_etl s1
inner join stage_country_code_etl s2
 on s1.country = s2.country_name