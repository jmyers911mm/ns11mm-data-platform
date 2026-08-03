-- setup_source_grants.sql — cross-database read grants for the single shared
-- source database (ADR-019).
-- ---------------------------------------------------------------------------
-- Every dbt environment (personal sandboxes, CI, prod) reads RAW/SEEDS landed
-- extracts from NS11MM_DW_DEV via the source_database var. This script grants
-- the read path to every role that builds elsewhere. Run as SECURITYADMIN (or
-- a role with MANAGE GRANTS) once, and re-run after adding schemas or roles.
--
-- Write access is NOT granted here: RAW stays append-only, written only by
-- LOADER_ROLE (ADR-001).

USE ROLE SECURITYADMIN;

-- Database usage
GRANT USAGE ON DATABASE NS11MM_DW_DEV TO ROLE TRANSFORMER_ROLE;   -- sandboxes + CI service user
GRANT USAGE ON DATABASE NS11MM_DW_DEV TO ROLE DEPLOY_PROD_ROLE;   -- prod builds

-- Source schemas: RAW (landed extracts) + SEEDS (dbt-seeded reference data)
GRANT USAGE ON SCHEMA NS11MM_DW_DEV.RAW   TO ROLE TRANSFORMER_ROLE;
GRANT USAGE ON SCHEMA NS11MM_DW_DEV.SEEDS TO ROLE TRANSFORMER_ROLE;
GRANT USAGE ON SCHEMA NS11MM_DW_DEV.RAW   TO ROLE DEPLOY_PROD_ROLE;
GRANT USAGE ON SCHEMA NS11MM_DW_DEV.SEEDS TO ROLE DEPLOY_PROD_ROLE;

-- Read on current and future tables in the source schemas
GRANT SELECT ON ALL TABLES    IN SCHEMA NS11MM_DW_DEV.RAW   TO ROLE TRANSFORMER_ROLE;
GRANT SELECT ON FUTURE TABLES IN SCHEMA NS11MM_DW_DEV.RAW   TO ROLE TRANSFORMER_ROLE;
GRANT SELECT ON ALL TABLES    IN SCHEMA NS11MM_DW_DEV.SEEDS TO ROLE TRANSFORMER_ROLE;
GRANT SELECT ON FUTURE TABLES IN SCHEMA NS11MM_DW_DEV.SEEDS TO ROLE TRANSFORMER_ROLE;
GRANT SELECT ON ALL TABLES    IN SCHEMA NS11MM_DW_DEV.RAW   TO ROLE DEPLOY_PROD_ROLE;
GRANT SELECT ON FUTURE TABLES IN SCHEMA NS11MM_DW_DEV.RAW   TO ROLE DEPLOY_PROD_ROLE;
GRANT SELECT ON ALL TABLES    IN SCHEMA NS11MM_DW_DEV.SEEDS TO ROLE DEPLOY_PROD_ROLE;
GRANT SELECT ON FUTURE TABLES IN SCHEMA NS11MM_DW_DEV.SEEDS TO ROLE DEPLOY_PROD_ROLE;

-- The GDPR erasure log also lives beside the source data (see gdpr_anonymize):
-- NS11MM_DW_DEV.INTERMEDIATE.GDPR_ERASURE_LOG. Erasure runs use DEPLOY_DEV_ROLE
-- (or higher) which already writes shared dev; no extra grant needed here.
