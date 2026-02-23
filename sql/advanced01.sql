-- Advanced SQL: CTEs, Window Functions, and KPI calculations
USE SCHEMA mfg_quality_dw.core;

-- 1) Daily defect rate + DPMO by line
WITH prod AS (
    SELECT
        date_key,
        line_key,
        SUM(units_produced) AS units_produced
    FROM fact_production
    GROUP BY date_key, line_key
), defect AS (
    SELECT
        date_key,
        line_key,
        SUM(defect_count) AS defects
    FROM fact_defects
    GROUP BY date_key, line_key
)
SELECT
    p.date_key,
    p.line_key,
    p.units_produced,
    COALESCE(d.defects, 0) AS defects,
    ROUND(COALESCE(d.defects, 0) / NULLIF(p.units_produced, 0), 6) AS defect_rate,
    ROUND((COALESCE(d.defects, 0) * 1000000) / NULLIF(p.units_produced, 0), 2) AS dpmo
FROM prod p
LEFT JOIN defect d
    ON p.date_key = d.date_key
   AND p.line_key = d.line_key;

-- 2) 7-day moving average defect trend per factory
WITH daily_factory_defects AS (
    SELECT
        date_key,
        factory_key,
        SUM(defect_count) AS total_defects
    FROM fact_defects
    GROUP BY date_key, factory_key
)
SELECT
    date_key,
    factory_key,
    total_defects,
    AVG(total_defects) OVER (
        PARTITION BY factory_key
        ORDER BY date_key
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS ma_7d_defects
FROM daily_factory_defects;

-- 3) Pareto ranking for defect categories
WITH defect_by_cat AS (
    SELECT
        dc.category_name,
        SUM(fd.defect_count) AS defect_volume
    FROM fact_defects fd
    JOIN dim_defect dd ON fd.defect_key = dd.defect_key
    JOIN dim_defect_category dc ON dd.defect_category_key = dc.defect_category_key
    GROUP BY dc.category_name
)
SELECT
    category_name,
    defect_volume,
    SUM(defect_volume) OVER () AS total_defect_volume,
    ROUND(100.0 * defect_volume / NULLIF(SUM(defect_volume) OVER (), 0), 2) AS pct_of_total,
    ROUND(100.0 * SUM(defect_volume) OVER (ORDER BY defect_volume DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
      / NULLIF(SUM(defect_volume) OVER (), 0), 2) AS cumulative_pct
FROM defect_by_cat
ORDER BY defect_volume DESC;

-- 4) MTTR proxy by machine (from downtime fact)
SELECT
    machine_key,
    COUNT(*) AS incidents,
    AVG(downtime_minutes) AS avg_repair_minutes,
    PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY downtime_minutes) AS p90_repair_minutes
FROM fact_downtime
WHERE downtime_type = 'UNPLANNED'
GROUP BY machine_key;
