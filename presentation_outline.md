# Final Presentation Outline

## 1. Business Context
- Manufacturing quality challenge and impact on cost, warranty, and throughput.
- Primary objective: reduce defect rate and accelerate root-cause analysis.

## 2. Solution Overview
- Unified analytics platform combining batch and streaming quality data.
- Warehouse-centric architecture with governed semantic layer.

## 3. Data Model
- Star schema core with selective snowflaking for hierarchy dimensions.
- Fact tables: defects, production, downtime.
- Dimensions: time, factory, line, machine, product, defect type, operator.

## 4. Engineering Implementation
- Python ETL for ingestion and quality checks.
- Spark batch for historical KPI aggregation.
- Spark structured streaming for near real-time anomaly signals.

## 5. Snowflake Design Choices
- Clustering keys on high-volume fact tables.
- Time travel and zero-copy clone strategy for recovery and safe releases.
- Variant column handling for semi-structured sensor payloads.

## 6. Security and Governance
- RBAC role hierarchy by persona (engineer, analyst, steward, admin).
- Dynamic data masking and row-level control examples.
- Auditability and governance checkpoints.

## 7. Performance and Cost Optimization
- Query profile-driven optimization.
- Warehouse sizing policy and auto-suspend tuning.
- Materialized views for heavy recurring KPI queries.

## 8. Dashboard Demonstration
- Defect trend, Pareto defect categories, line comparison, yield monitor.
- Drill-down from site -> line -> machine.

## 9. Outcomes and Roadmap
- Expected KPI improvements.
- Next phase: predictive maintenance and closed-loop alerts.
