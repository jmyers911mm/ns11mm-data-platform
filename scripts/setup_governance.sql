-- ---------------------------------------------------------------------------
-- setup_governance.sql — one-time governance bootstrap for a dbt target DB
-- ---------------------------------------------------------------------------
-- Creates the tags that macros/operations/apply_governance_tags.sql assigns
-- in its on-run-end hook. The macro assumes these exist ("Tags are created
-- outside this repo in <tag_db>.PUBLIC") — this script is that outside step.
--
-- RUN ONCE PER DATABASE dbt builds into, as a role that can create schema
-- objects there (SYSADMIN or the DB owner):
--
--     USE DATABASE NS11MM_DW_DEV_JMYERS;   -- then re-run for:
--                                          --   NS11MM_DW_DEV
--                                          --   NS11MM_DW_DEV_CI
--                                          --   NS11MM_DW_PROD
--     -- then execute this whole file
--
-- If you later centralize tags in one governance DB instead, run this once
-- there and pass --vars 'governance_tag_database: <that_db>' to dbt (the
-- macro already supports it). Keep per-target tags until that decision is
-- made deliberately.
--
-- Prerequisite for: dbt run/build/compile on any target (the on-run-end
-- hook fails with "Tag ... does not exist or not authorized" without it).
-- Referenced from: docs/architecture/DATA_CLASSIFICATION.md
-- ---------------------------------------------------------------------------

-- Tags live in PUBLIC of the target database, matching the macro's
-- {{ tag_db }}.PUBLIC.<TAG> references.

-- 1. SENSITIVITY — classification level.
--    Allowed values = exactly the set the macro assigns.
CREATE TAG IF NOT EXISTS PUBLIC.SENSITIVITY
  ALLOWED_VALUES 'PII', 'CONFIDENTIAL', 'INTERNAL', 'PUBLIC'
  COMMENT = 'Data classification level. Assigned by dbt on-run-end hook (apply_governance_tags). Levels defined in docs/architecture/DATA_CLASSIFICATION.md.';

-- 2. DATA_DOMAIN — business domain of the object.
--    Allowed values = the domains currently in the macro's assignment list.
--    NOTE: adding a new domain to the macro requires adding it here first
--    (ALTER TAG ... ADD ALLOWED_VALUES '<NEW>'), or the hook run fails.
CREATE TAG IF NOT EXISTS PUBLIC.DATA_DOMAIN
  ALLOWED_VALUES 'MARKETING', 'ECOMMERCE', 'TICKETING', 'REFERENCE',
                 'FINANCE', 'ATTENDANCE', 'RETAIL'
  COMMENT = 'Business domain. Assigned by dbt on-run-end hook (apply_governance_tags).';

-- 3. DATA_OWNER — accountable person. Deliberately unrestricted:
--    owner names change; constraining them here would couple personnel
--    changes to DDL migrations.
CREATE TAG IF NOT EXISTS PUBLIC.DATA_OWNER
  COMMENT = 'Accountable data owner (person). Assigned by dbt on-run-end hook (apply_governance_tags).';

-- ---------------------------------------------------------------------------
-- Grants — the role executing dbt must hold APPLY on each tag (tag owner
-- is exempt, so if the same role runs this script and runs dbt, these are
-- redundant but harmless). Uncomment the lines for the roles that run dbt
-- against THIS database:
--
--   dev sandboxes + CI ........ TRANSFORMER_ROLE
--   shared dev deploys ........ DEPLOY_DEV_ROLE
--   prod deploys .............. DEPLOY_PROD_ROLE
-- ---------------------------------------------------------------------------

-- GRANT APPLY ON TAG PUBLIC.SENSITIVITY TO ROLE TRANSFORMER_ROLE;
-- GRANT APPLY ON TAG PUBLIC.DATA_DOMAIN TO ROLE TRANSFORMER_ROLE;
-- GRANT APPLY ON TAG PUBLIC.DATA_OWNER  TO ROLE TRANSFORMER_ROLE;

-- GRANT APPLY ON TAG PUBLIC.SENSITIVITY TO ROLE DEPLOY_DEV_ROLE;
-- GRANT APPLY ON TAG PUBLIC.DATA_DOMAIN TO ROLE DEPLOY_DEV_ROLE;
-- GRANT APPLY ON TAG PUBLIC.DATA_OWNER  TO ROLE DEPLOY_DEV_ROLE;

-- GRANT APPLY ON TAG PUBLIC.SENSITIVITY TO ROLE DEPLOY_PROD_ROLE;
-- GRANT APPLY ON TAG PUBLIC.DATA_DOMAIN TO ROLE DEPLOY_PROD_ROLE;
-- GRANT APPLY ON TAG PUBLIC.DATA_OWNER  TO ROLE DEPLOY_PROD_ROLE;

-- ---------------------------------------------------------------------------
-- Masking policies (apply_masking_policies.sql) — PENDING.
-- That macro runs in the same on-run-end hook and its policies also have no
-- creation DDL in the repo. Add the CREATE MASKING POLICY statements here
-- (policy names must match the macro's references) before relying on the
-- hook in prod. Until then a fresh database will pass tagging and fail one
-- step later on the first missing policy.
-- ---------------------------------------------------------------------------

-- Verify:
SHOW TAGS IN SCHEMA PUBLIC;