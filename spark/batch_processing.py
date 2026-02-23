import argparse

from pyspark.sql import SparkSession
from pyspark.sql import functions as F


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Spark batch processing for manufacturing defects")
    parser.add_argument("--defects", required=True)
    parser.add_argument("--production", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    spark = (
        SparkSession.builder.appName("mfg-defect-batch")
        .config("spark.sql.session.timeZone", "UTC")
        .getOrCreate()
    )

    defects = spark.read.option("header", True).csv(args.defects, inferSchema=True)
    production = spark.read.option("header", True).csv(args.production, inferSchema=True)

    defects = defects.withColumn("event_ts", F.to_timestamp("event_ts"))
    production = production.withColumn("event_date", F.to_date("event_date"))

    defect_daily = (
        defects.groupBy(
            F.date_format("event_ts", "yyyyMMdd").alias("date_key"),
            "factory_id",
            "line_id",
        )
        .agg(F.sum("defect_count").alias("total_defects"))
    )

    prod_daily = (
        production.groupBy(
            F.date_format("event_date", "yyyyMMdd").alias("date_key"),
            "factory_id",
            "line_id",
        )
        .agg(F.sum("units_produced").alias("total_units"))
    )

    kpis = (
        prod_daily.join(defect_daily, ["date_key", "factory_id", "line_id"], "left")
        .fillna({"total_defects": 0})
        .withColumn("defect_rate", F.col("total_defects") / F.when(F.col("total_units") == 0, None).otherwise(F.col("total_units")))
        .withColumn("dpmo", (F.col("total_defects") * F.lit(1_000_000)) / F.when(F.col("total_units") == 0, None).otherwise(F.col("total_units")))
    )

    (
        kpis.coalesce(1)
        .write.mode("overwrite")
        .option("header", True)
        .csv(args.output)
    )

    spark.stop()
