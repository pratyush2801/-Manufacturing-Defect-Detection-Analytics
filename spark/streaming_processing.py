import argparse

from pyspark.sql import SparkSession
from pyspark.sql import functions as F
from pyspark.sql.types import IntegerType, StringType, StructField, StructType, TimestampType


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Spark structured streaming for defect events")
    parser.add_argument("--input", required=True, help="Input directory for streaming JSON files")
    parser.add_argument("--checkpoint", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    spark = (
        SparkSession.builder.appName("mfg-defect-stream")
        .config("spark.sql.session.timeZone", "UTC")
        .getOrCreate()
    )

    schema = StructType([
        StructField("event_ts", TimestampType(), True),
        StructField("factory_id", StringType(), True),
        StructField("line_id", StringType(), True),
        StructField("machine_id", StringType(), True),
        StructField("defect_type", StringType(), True),
        StructField("defect_count", IntegerType(), True),
    ])

    stream_df = (
        spark.readStream.schema(schema)
        .option("maxFilesPerTrigger", 1)
        .json(args.input)
    )

    agg = (
        stream_df.withWatermark("event_ts", "10 minutes")
        .groupBy(
            F.window("event_ts", "5 minutes"),
            "factory_id",
            "line_id",
            "defect_type",
        )
        .agg(F.sum("defect_count").alias("defect_events"))
    )

    query = (
        agg.writeStream.outputMode("append")
        .format("parquet")
        .option("path", args.output)
        .option("checkpointLocation", args.checkpoint)
        .trigger(processingTime="30 seconds")
        .start()
    )

    query.awaitTermination()
