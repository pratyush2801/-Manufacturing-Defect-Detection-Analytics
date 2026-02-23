-- Manufacturing Defect Detection Analytics
-- Star/Snowflake Warehouse Schema (Snowflake SQL)

CREATE OR REPLACE DATABASE mfg_quality_dw;
CREATE OR REPLACE SCHEMA mfg_quality_dw.core;
USE SCHEMA mfg_quality_dw.core;

-- =========================
-- Dimension tables
-- =========================

CREATE OR REPLACE TABLE dim_date (
    date_key            NUMBER PRIMARY KEY,
    full_date           DATE,
    day_of_week         VARCHAR,
    day_name            VARCHAR,
    week_of_year        NUMBER,
    month_number        NUMBER,
    month_name          VARCHAR,
    quarter_number      NUMBER,
    year_number         NUMBER,
    is_weekend          BOOLEAN
);

CREATE OR REPLACE TABLE dim_factory (
    factory_key         NUMBER AUTOINCREMENT PRIMARY KEY,
    factory_code        VARCHAR,
    factory_name        VARCHAR,
    country             VARCHAR,
    region              VARCHAR,
    plant_type          VARCHAR,
    is_active           BOOLEAN,
    effective_from      TIMESTAMP_NTZ,
    effective_to        TIMESTAMP_NTZ
);

CREATE OR REPLACE TABLE dim_line (
    line_key            NUMBER AUTOINCREMENT PRIMARY KEY,
    factory_key         NUMBER,
    line_code           VARCHAR,
    line_name           VARCHAR,
    line_type           VARCHAR,
    max_throughput_hr   NUMBER,
    is_active           BOOLEAN,
    effective_from      TIMESTAMP_NTZ,
    effective_to        TIMESTAMP_NTZ,
    CONSTRAINT fk_line_factory FOREIGN KEY (factory_key) REFERENCES dim_factory(factory_key)
);

CREATE OR REPLACE TABLE dim_machine (
    machine_key         NUMBER AUTOINCREMENT PRIMARY KEY,
    line_key            NUMBER,
    machine_code        VARCHAR,
    machine_name        VARCHAR,
    machine_model       VARCHAR,
    criticality_tier    VARCHAR,
    install_date        DATE,
    CONSTRAINT fk_machine_line FOREIGN KEY (line_key) REFERENCES dim_line(line_key)
);

CREATE OR REPLACE TABLE dim_product_family (
    product_family_key  NUMBER AUTOINCREMENT PRIMARY KEY,
    product_family_code VARCHAR,
    product_family_name VARCHAR
);

CREATE OR REPLACE TABLE dim_product (
    product_key         NUMBER AUTOINCREMENT PRIMARY KEY,
    product_family_key  NUMBER,
    sku                 VARCHAR,
    product_name        VARCHAR,
    revision            VARCHAR,
    unit_cost           NUMBER(12,2),
    CONSTRAINT fk_product_family FOREIGN KEY (product_family_key) REFERENCES dim_product_family(product_family_key)
);

CREATE OR REPLACE TABLE dim_defect_category (
    defect_category_key NUMBER AUTOINCREMENT PRIMARY KEY,
    category_code       VARCHAR,
    category_name       VARCHAR,
    severity_rank       NUMBER
);

CREATE OR REPLACE TABLE dim_defect (
    defect_key          NUMBER AUTOINCREMENT PRIMARY KEY,
    defect_category_key NUMBER,
    defect_code         VARCHAR,
    defect_name         VARCHAR,
    root_cause_group    VARCHAR,
    CONSTRAINT fk_defect_category FOREIGN KEY (defect_category_key) REFERENCES dim_defect_category(defect_category_key)
);

CREATE OR REPLACE TABLE dim_operator (
    operator_key        NUMBER AUTOINCREMENT PRIMARY KEY,
    operator_id         VARCHAR,
    operator_name       VARCHAR,
    certification_level VARCHAR,
    shift_code          VARCHAR,
    hire_date           DATE
);

-- =========================
-- Fact tables
-- =========================

CREATE OR REPLACE TABLE fact_production (
    production_id       NUMBER AUTOINCREMENT,
    date_key            NUMBER,
    factory_key         NUMBER,
    line_key            NUMBER,
    machine_key         NUMBER,
    product_key         NUMBER,
    operator_key        NUMBER,
    units_produced      NUMBER,
    run_time_minutes    NUMBER,
    planned_downtime_m  NUMBER,
    unplanned_downtime_m NUMBER,
    ingestion_ts        TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (production_id)
);

CREATE OR REPLACE TABLE fact_defects (
    defect_event_id     NUMBER AUTOINCREMENT,
    date_key            NUMBER,
    factory_key         NUMBER,
    line_key            NUMBER,
    machine_key         NUMBER,
    product_key         NUMBER,
    operator_key        NUMBER,
    defect_key          NUMBER,
    defect_count        NUMBER,
    defect_cost         NUMBER(14,2),
    event_ts            TIMESTAMP_NTZ,
    sensor_payload      VARIANT,
    ingestion_ts        TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (defect_event_id)
);

CREATE OR REPLACE TABLE fact_downtime (
    downtime_id         NUMBER AUTOINCREMENT,
    date_key            NUMBER,
    factory_key         NUMBER,
    line_key            NUMBER,
    machine_key         NUMBER,
    downtime_type       VARCHAR,
    downtime_minutes    NUMBER,
    reason_code         VARCHAR,
    event_ts            TIMESTAMP_NTZ,
    PRIMARY KEY (downtime_id)
);
