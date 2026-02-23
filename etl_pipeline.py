import argparse
from pathlib import Path

import pandas as pd


def load_csv(path: Path, required_columns: list[str]) -> pd.DataFrame:
    df = pd.read_csv(path)
    missing = [c for c in required_columns if c not in df.columns]
    if missing:
        raise ValueError(f"Missing columns in {path}: {missing}")
    return df


def transform(defects: pd.DataFrame, production: pd.DataFrame) -> tuple[pd.DataFrame, pd.DataFrame]:
    defects = defects.copy()
    production = production.copy()

    defects["event_ts"] = pd.to_datetime(defects["event_ts"], errors="coerce")
    production["event_date"] = pd.to_datetime(production["event_date"], errors="coerce")

    defects = defects.dropna(subset=["event_ts", "line_id", "defect_count"])
    production = production.dropna(subset=["event_date", "line_id", "units_produced"])

    defects["date_key"] = defects["event_ts"].dt.strftime("%Y%m%d").astype(int)
    production["date_key"] = production["event_date"].dt.strftime("%Y%m%d").astype(int)

    defects["defect_count"] = defects["defect_count"].clip(lower=0)
    production["units_produced"] = production["units_produced"].clip(lower=0)

    return defects, production


def aggregate_kpis(defects: pd.DataFrame, production: pd.DataFrame) -> pd.DataFrame:
    defect_daily = defects.groupby(["date_key", "factory_id", "line_id"], as_index=False)["defect_count"].sum()
    prod_daily = production.groupby(["date_key", "factory_id", "line_id"], as_index=False)["units_produced"].sum()

    merged = prod_daily.merge(defect_daily, on=["date_key", "factory_id", "line_id"], how="left")
    merged["defect_count"] = merged["defect_count"].fillna(0)
    merged["defect_rate"] = merged["defect_count"] / merged["units_produced"].replace({0: pd.NA})
    merged["dpmo"] = (merged["defect_count"] * 1_000_000) / merged["units_produced"].replace({0: pd.NA})

    return merged


def save_outputs(defects: pd.DataFrame, production: pd.DataFrame, kpis: pd.DataFrame, output_dir: Path) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    defects.to_parquet(output_dir / "defects_curated.parquet", index=False)
    production.to_parquet(output_dir / "production_curated.parquet", index=False)
    kpis.to_parquet(output_dir / "daily_quality_kpis.parquet", index=False)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Manufacturing quality ETL pipeline")
    parser.add_argument("--defects", type=Path, required=True, help="Path to defects CSV")
    parser.add_argument("--production", type=Path, required=True, help="Path to production CSV")
    parser.add_argument("--output", type=Path, required=True, help="Output directory")

    args = parser.parse_args()

    defects_required = ["event_ts", "factory_id", "line_id", "machine_id", "defect_type", "defect_count"]
    production_required = ["event_date", "factory_id", "line_id", "units_produced"]

    defects_df = load_csv(args.defects, defects_required)
    production_df = load_csv(args.production, production_required)

    defects_curated, production_curated = transform(defects_df, production_df)
    kpi_df = aggregate_kpis(defects_curated, production_curated)
    save_outputs(defects_curated, production_curated, kpi_df, args.output)

    print(f"ETL complete. Wrote curated data to: {args.output}")
