# Architecture Diagram and Design

```mermaid
flowchart LR
    A[Manufacturing Sources\nMES/SCADA/ERP/IoT Sensors] --> B[Ingestion Layer\nBatch + Streaming]
    B --> C[Raw Landing\nObject Storage]
    C --> D[Processing Layer\nPython ETL + Spark]
    D --> E[Snowflake Staging]
    E --> F[Warehouse Core\nStar/Snowflake Schema]
    F --> G[Semantic / Data Marts\nQuality, OEE, Yield]
    G --> H[BI Dashboard\nStreamlit / BI Tool]

    I[Governance\nCatalog, Lineage, DQ Rules] -.-> D
    I -.-> F
    J[Security\nRBAC + Masking + Auditing] -.-> E
    J -.-> F

    K[ML / Alerting\nDefect Spike Detection] --> H
```

## Layer Responsibilities

1. **Source systems**
   - Machine telemetry, quality inspections, production records, shift/operator logs.
2. **Ingestion**
   - Batch for ERP/MES extracts.
   - Streaming for sensor events and inline inspection alerts.
3. **Storage + Processing**
   - Raw immutable storage for replayability.
   - ETL/ELT standardization, schema validation, deduplication.
4. **Warehouse**
   - Conformed dimensions and process-specific fact tables.
5. **Consumption**
   - KPI dashboard: defect rate, DPMO, first-pass yield, MTTR, Pareto charts.

## Non-Functional Design

- **Scalability**: partition by event date and factory/site.
- **Reliability**: idempotent loads, checkpointing for streaming.
- **Security**: least privilege access model and masking for operator PII.
- **Governance**: data quality scorecards and lineage documentation.
