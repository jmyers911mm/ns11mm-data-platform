-- TRANSFORMATION: t_dim_facility
-- DESC: Facility

-- WRITES: 911DW:.dim_facility (InsertUpdate)


-- ===== STEP: SenSource - Facility [TableInput] conn=SenSource =====
SELECT
Facility,FacilityName from dbo.Facility