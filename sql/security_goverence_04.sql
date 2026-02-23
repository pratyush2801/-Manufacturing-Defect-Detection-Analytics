-- Security: RBAC + masking + row access policy
USE ROLE SECURITYADMIN;

-- Roles
CREATE ROLE IF NOT EXISTS role_quality_admin;
CREATE ROLE IF NOT EXISTS role_quality_engineer;
CREATE ROLE IF NOT EXISTS role_quality_analyst;
CREATE ROLE IF NOT EXISTS role_quality_auditor;

-- Grant role hierarchy
GRANT ROLE role_quality_analyst TO ROLE role_quality_engineer;
GRANT ROLE role_quality_engineer TO ROLE role_quality_admin;

-- Warehouse/db/schema permissions (example)
GRANT USAGE ON DATABASE mfg_quality_dw TO ROLE role_quality_analyst;
GRANT USAGE ON SCHEMA mfg_quality_dw.core TO ROLE role_quality_analyst;
GRANT SELECT ON ALL TABLES IN SCHEMA mfg_quality_dw.core TO ROLE role_quality_analyst;

-- Dynamic masking policy for operator name
CREATE OR REPLACE MASKING POLICY mask_operator_name AS (val STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() IN ('ROLE_QUALITY_ADMIN', 'ROLE_QUALITY_ENGINEER') THEN val
        ELSE 'REDACTED'
    END;

ALTER TABLE mfg_quality_dw.core.dim_operator
MODIFY COLUMN operator_name
SET MASKING POLICY mask_operator_name;

-- Row access policy: restrict factory visibility by role naming pattern
CREATE OR REPLACE ROW ACCESS POLICY rap_factory_scope AS (factory_code STRING) RETURNS BOOLEAN ->
    CASE
        WHEN CURRENT_ROLE() = 'ROLE_QUALITY_ADMIN' THEN TRUE
        WHEN CURRENT_ROLE() = 'ROLE_QUALITY_ENGINEER' AND factory_code IN ('F001','F002') THEN TRUE
        WHEN CURRENT_ROLE() = 'ROLE_QUALITY_ANALYST' AND factory_code = 'F001' THEN TRUE
        ELSE FALSE
    END;

ALTER TABLE mfg_quality_dw.core.dim_factory
ADD ROW ACCESS POLICY rap_factory_scope ON (factory_code);

-- Governance checks
-- SHOW MASKING POLICIES;
-- SHOW ROW ACCESS POLICIES;
-- SELECT * FROM SNOWFLAKE.ACCOUNT_USAGE.ACCESS_HISTORY LIMIT 100;
