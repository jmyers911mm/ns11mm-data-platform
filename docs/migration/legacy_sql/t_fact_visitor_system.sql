-- TRANSFORMATION: t_fact_visitor_system
-- DESC: 

-- WRITES: 911DW:.fact_visitor_system (InsertUpdate)
-- LOOKUP: 911DW:.stage_state_code_etl
-- LOOKUP: 911DW:.dim_city
-- LOOKUP: 911DW:.stage_dim_country_etl
-- LOOKUP: 911DW:.dim_date
-- LOOKUP: 911DW:.dim_flashversion
-- LOOKUP: 911DW:.dim_ismobile
-- LOOKUP: 911DW:.dim_operatingsystem
-- LOOKUP: 911DW:.dim_operatingsystemversion
-- LOOKUP: 911DW:.dim_state


-- ===== STEP: Get delta fact [TableInput] conn=911DW =====
SELECT
  operatingSystem
, operatingSystemVersion
, flashVersion
, isMobile
, city
, region
, date
, visits
, visitors
, newVisits
, timeOnSite
, entrances
, bounces
, pageviews
, uniquePageviews
, exits
FROM stage_visitor_system_etl