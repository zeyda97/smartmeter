from pyspark.sql import SparkSession
from pyspark.ml import PipelineModel
from prometheus_client import start_http_server, Gauge
from common.writer import Writer
from common.utilities import Utilities

# Prometheus metrics
predictions_metric = Gauge("spark_app5_predictions", "Number of predictions made")
cpu_usage_metric = Gauge("spark_app5_cpu_usage", "CPU usage of Spark App5")  # Placeholder metric

def expose_metrics():
    # Start the Prometheus metrics HTTP server
    start_http_server(8000)  # Prometheus will scrape metrics from this port
    print("Prometheus metrics server started on port 8000")

def main():
    # Start exposing Prometheus metrics
    expose_metrics()

    # Initialize Spark Session
    spark = SparkSession.builder \
        .appName("Spark_App5") \
        .getOrCreate()

    # Initialize Writer and Utilities
    writer = Writer()
    utils = Utilities()

    # Step 1: Load trained model from MLflow
    model_uri = "mlruns:/1/model_lr"  # Replace with your MLflow model URI
    print(f"Loading model from MLflow: {model_uri}")
    
    try:
        model = PipelineModel.load(utils.load_model_from_mlflow(model_uri))
    except Exception as e:
        print(f"Error loading model from MLflow: {e}")
        return

    # Step 2: Read raw forecast data from Kafka
    kafka_bootstrap_servers = "kafka:9092"  # Replace with your Kafka broker address
    kafka_topic = "forecast_topic"  # Replace with your Kafka topic
    print(f"Reading raw data from Kafka topic: {kafka_topic}")

    try:
        raw_data = spark.readStream \
            .format("kafka") \
            .option("kafka.bootstrap.servers", kafka_bootstrap_servers) \
            .option("subscribe", kafka_topic) \
            .load()
    except Exception as e:
        print(f"Error connecting to Kafka: {e}")
        return

    # Deserialize Kafka messages and preprocess data
    feature_columns = ["voltage", "timestamp", "processed_time"]  # Replace with actual feature columns
    raw_data_parsed = utils.deserialize_kafka_data(raw_data, feature_columns)
    data = utils.preprocess_data(raw_data_parsed, feature_columns)

    if data is None:
        print("Data preprocessing failed. Exiting.")
        return

    # Step 3: Generate predictions using the loaded model
    print("Generating predictions...")
    predictions = model.transform(data)

    # Step 4: Update Prometheus metrics
    predictions_count = predictions.count()  # Placeholder for actual prediction counts
    predictions_metric.set(predictions_count)
    print(f"Predictions metric updated: {predictions_count}")

    # Log a placeholder CPU usage metric (update this with actual CPU metrics if available)
    cpu_usage_metric.set(50)  # Example value for CPU usage

    # Step 5: Write predictions to Kafka and optionally to Delta Lake
    output_kafka_topic = "predictions_topic"  # Replace with your Kafka output topic
    try:
        writer.write_stream_to_kafka(predictions, output_kafka_topic)
        print(f"Predictions written to Kafka topic: {output_kafka_topic}")
    except Exception as e:
        print(f"Error writing predictions to Kafka: {e}")
        return

    # Optional: Save predictions to Delta Lake
    delta_table_path = "hdfs://namenode:9000/user/hive/warehouse/predictions_delta"  # Update as needed
    writer.write_stream_to_delta(predictions, delta_table_path)
    print(f"Predictions written to Delta Lake at: {delta_table_path}")

    print("Spark App5 completed successfully!")

if __name__ == "__main__":
    main()