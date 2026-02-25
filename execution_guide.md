# Execution Guide (Step-by-Step)

This guide shows the exact sequence to run the project end-to-end.

## 0) Prerequisites

- Python 3.10+
- Java 8/11+ (for PySpark)
- Optional: Snowflake account (for SQL scripts)

## 1) Clone and enter repository

```bash
git clone <your-repo-url>
cd -Manufacturing-Defect-Detection-Analytics
```

## 2) Create and activate a virtual environment

```bash
python -m venv .venv
source .venv/bin/activate
```

## 3) Install dependencies

```bash
pip install -r requirements.txt
```

If your environment has no internet/proxy restrictions, this should install:
- pandas, numpy, pyarrow
- pyspark
- streamlit + plotly

## 4) Run Python ETL (curation + KPI parquet outputs)

```bash
python python_etl/etl_pipeline.py \
  --defects data/samples/defects.csv \
  --production data/samples/production.csv \
  --output data/processed
```

Expected outputs:
- `data/processed/defects_curated.parquet`
- `data/processed/production_curated.parquet`
- `data/processed/daily_quality_kpis.parquet`

## 5) Run Spark batch pipeline

```bash
python spark/batch_processing.py \
  --defects data/samples/defects.csv \
  --production data/samples/production.csv \
  --output data/spark_output/batch
```

Expected output: CSV files under `data/spark_output/batch`.

## 6) Run Spark structured streaming (file source simulation)

Create folders:

```bash
mkdir -p data/stream/input data/stream/checkpoint data/stream/output
```

Start streaming job in terminal A:

```bash
python spark/streaming_processing.py \
  --input data/stream/input \
  --checkpoint data/stream/checkpoint \
  --output data/stream/output
```

In terminal B, drop JSON files into input folder (micro-batches):

```bash
cat > data/stream/input/batch_001.json <<'JSON'
{"event_ts":"2024-01-05T10:00:00","factory_id":"F001","line_id":"L01","machine_id":"M01","defect_type":"Scratch","defect_count":2}
{"event_ts":"2024-01-05T10:02:00","factory_id":"F001","line_id":"L01","machine_id":"M01","defect_type":"Dent","defect_count":1}
JSON
```

The streaming job will aggregate 5-minute windows and write parquet to `data/stream/output`.

## 7) Launch dashboard

```bash
streamlit run dashboard/app.py
```

Open the URL printed by Streamlit (commonly `http://localhost:8501`).

## 8) Execute Snowflake SQL scripts (optional)

Order to run:
1. `sql/01_schema_design.sql`
2. `sql/02_advanced_analytics.sql`
3. `sql/03_snowflake_optimization.sql`
4. `sql/04_security_governance.sql`
5. `sql/05_performance_tuning.sql`

Using SnowSQL example:

```bash
snowsql -a <account> -u <user> -r <role> -w <warehouse> -d MFG_QUALITY_DW -s CORE -f sql/01_schema_design.sql
```

Repeat `-f` for each script.

## 9) Troubleshooting

- `ModuleNotFoundError`: ensure venv is activated and dependencies installed.
- PySpark errors: verify Java is installed and `JAVA_HOME` is set.
- Streamlit missing: rerun `pip install -r requirements.txt`.
- Network-restricted envs: dependency installation may fail if external package indexes are blocked.
