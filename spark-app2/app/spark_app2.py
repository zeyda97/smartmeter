from pyspark.sql import SparkSession
from pyspark.sql.functions import from_json, col, current_timestamp

KAFKA_BROKER = "kafka:9092"
INPUT_TOPIC = "sensor-data"
HDFS_OUTPUT = "hdfs://namenode:8020/delta/sensor-data"

# Create SparkSession
spark = SparkSession.builder \
    .appName("SparkApp2-DeltaProcessor") \
    .getOrCreate()

# Read data from Kafka
raw_stream = spark.readStream \
    .format("kafka") \
    .option("kafka.bootstrap.servers", KAFKA_BROKER) \
    .option("subscribe", INPUT_TOPIC) \
    .option("startingOffsets", "latest") \
    .load()

# Define schema for Kafka data
schema = "meter_id INT, voltage DOUBLE, timestamp DOUBLE"

# Parse JSON payload and transform data
processed_stream = raw_stream.selectExpr("CAST(value AS STRING)") \
    .select(from_json(col("value"), schema).alias("data")) \
    .select("data.*") \
    .withColumn("processed_time", current_timestamp())

# Write the processed data to HDFS in delta format
query = processed_stream.writeStream \
    .format("parquet") \
    .option("path", HDFS_OUTPUT) \
    .option("checkpointLocation", "/delta/checkpoints/sensor-data") \
    .outputMode("append") \
    .start()

query.awaitTermination()