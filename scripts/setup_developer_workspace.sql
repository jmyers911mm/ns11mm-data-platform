-- NS11MM Data Platform — Developer Workspace Setup (parameterized)
-- Co-authored with CoCo
-- Run once per new developer to provision their personal dev environment.
-- Set the developer's Snowflake username below, then execute the entire script.

SET dev_username = 'KRAMSEY';
SET dev_db = 'NS11MM_DW_DEV_' || $dev_username;
SET dev_db_comment = 'Personal dev database for ' || $dev_username;
SET dev_raw = $dev_db || '.RAW';
SET dev_silver = $dev_db || '.SILVER';
SET dev_gold = $dev_db || '.GOLD';
SET dev_ml = $dev_db || '.ML_FEATURES';
SET dev_audit = $dev_db || '.SILVER.DBT_RUN_AUDIT_LOG';

-- 1. Create personal dev database
CREATE DATABASE IF NOT EXISTS IDENTIFIER($dev_db);
ALTER DATABASE IDENTIFIER($dev_db) SET COMMENT = $dev_db_comment;

-- 2. Create schemas mirroring production
CREATE SCHEMA IF NOT EXISTS IDENTIFIER($dev_raw);
CREATE SCHEMA IF NOT EXISTS IDENTIFIER($dev_silver);
CREATE SCHEMA IF NOT EXISTS IDENTIFIER($dev_gold);
CREATE SCHEMA IF NOT EXISTS IDENTIFIER($dev_ml);

-- 3. Grant permissions
GRANT USAGE ON DATABASE IDENTIFIER($dev_db) TO ROLE TRANSFORMER_ROLE;
GRANT ALL ON ALL SCHEMAS IN DATABASE IDENTIFIER($dev_db) TO ROLE TRANSFORMER_ROLE;
GRANT ALL ON FUTURE SCHEMAS IN DATABASE IDENTIFIER($dev_db) TO ROLE TRANSFORMER_ROLE;
GRANT ALL ON FUTURE TABLES IN DATABASE IDENTIFIER($dev_db) TO ROLE TRANSFORMER_ROLE;

-- 4. Create audit log table
CREATE TABLE IF NOT EXISTS IDENTIFIER($dev_audit) (
    model_name          VARCHAR,
    run_timestamp       TIMESTAMP_TZ,
    status              VARCHAR,
    rows_affected       INTEGER,
    error_message       VARCHAR
);

-- 5. Grant LOADER_ROLE access to RAW schema for pipeline testing
GRANT USAGE ON DATABASE IDENTIFIER($dev_db) TO ROLE LOADER_ROLE;
GRANT USAGE ON SCHEMA IDENTIFIER($dev_raw) TO ROLE LOADER_ROLE;
GRANT CREATE TABLE ON SCHEMA IDENTIFIER($dev_raw) TO ROLE LOADER_ROLE;
GRANT INSERT ON FUTURE TABLES IN SCHEMA IDENTIFIER($dev_raw) TO ROLE LOADER_ROLE;
GRANT INSERT ON ALL TABLES IN SCHEMA IDENTIFIER($dev_raw) TO ROLE LOADER_ROLE;
