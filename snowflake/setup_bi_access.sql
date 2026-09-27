-- ============================================================
-- BI ACCESS SETUP: read-only role + dedicated warehouse for Power BI
-- Safe to re-run (idempotent) thanks to IF NOT EXISTS
-- ============================================================
USE ROLE ACCOUNTADMIN;  -- only an admin can create roles and grants

-- 1) A small, separate compute engine for dashboards
CREATE WAREHOUSE IF NOT EXISTS BI_WH
  WAREHOUSE_SIZE = 'XSMALL'   -- smallest size = cheapest
  AUTO_SUSPEND = 60           -- switch off after 60s idle (stops credit burn)
  AUTO_RESUME = TRUE          -- wake up automatically when queried
  INITIALLY_SUSPENDED = TRUE; -- don't start running right now

-- 2) The "visitor badge" role
CREATE ROLE IF NOT EXISTS BI_READER;

-- 3) Let the role use the warehouse, and "open the doors" to database and schema
GRANT USAGE ON WAREHOUSE BI_WH              TO ROLE BI_READER;
GRANT USAGE ON DATABASE  SAAS_PROD          TO ROLE BI_READER;
GRANT USAGE ON SCHEMA    SAAS_PROD.DBT_DEV  TO ROLE BI_READER;

-- 4) Read-only access to everything that exists now...
GRANT SELECT ON ALL TABLES IN SCHEMA SAAS_PROD.DBT_DEV TO ROLE BI_READER;
GRANT SELECT ON ALL VIEWS  IN SCHEMA SAAS_PROD.DBT_DEV TO ROLE BI_READER;

-- 5) ...and to everything dbt creates in the future
--    (dbt rebuilds tables on every run, which wipes normal grants)
GRANT SELECT ON FUTURE TABLES IN SCHEMA SAAS_PROD.DBT_DEV TO ROLE BI_READER;
GRANT SELECT ON FUTURE VIEWS  IN SCHEMA SAAS_PROD.DBT_DEV TO ROLE BI_READER;

-- 6) Give the badge to your user
GRANT ROLE BI_READER TO USER AMBUSSS;

-- 7) Test: act as the badge-holder and read a Gold table
USE ROLE BI_READER;
USE WAREHOUSE BI_WH;
SELECT COUNT(*) AS row_count FROM SAAS_PROD.DBT_DEV.FCT_MRR_MOVEMENTS;
DESCRIBE TABLE SAAS_PROD.DBT_DEV.FCT_MRR_MOVEMENTS;
DESCRIBE TABLE SAAS_PROD.DBT_DEV.DIM_CUSTOMERS;