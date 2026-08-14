-- TRANSFORMATION: t_dim_country
-- DESC: Country Dimension from Ecommerce

-- WRITES: 911DW:.dim_country (InsertUpdate)


-- ===== STEP: Ecommerce [TableInput] conn=Ecommerce =====
SELECT
country_iso_code_2
FROM uc_countries
group by 1