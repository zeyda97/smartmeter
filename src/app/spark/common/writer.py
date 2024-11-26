from app.spark.common.kafkaconfig import KafkaConfig
from app.spark.common.deltaconfig import DeltaConfig
from app.spark.common.config import Config
from pyspark.ml.regression import LinearRegressionModel

class Writer:
    def __init__(self):
        self.kafka_config = KafkaConfig()
        self.delta_config = DeltaConfig()

    def write_stream_to_kafka(self, df):
        """
        Writes streaming data to Kafka topics.
        """
        return (
            df.writeStream
            .format("kafka")
            .option("kafka.bootstrap.servers", self.kafka_config.bootstrap_servers)
            .option("topic", self.kafka_config.output_topic)
            .option("checkpointLocation", self.kafka_config.checkpoint_location)
            .trigger(processingTime="1 minute")
            .outputMode("complete")
            .start()
            .awaitTermination()
        )

    def write_stream_to_delta(self, df, path: str = None):
        """
        Writes streaming data to Delta Lake. If no path is provided, uses the default from config.
        """
        if path is None:
            path = Config.HDFS_DATA_LAKE_PATH
        return (
            df.writeStream
            .option("checkpointLocation", "/tmp")
            .option("path", path)
            .outputMode("append")
            .trigger(processingTime="1 minute")
            .start()
            .awaitTermination()
        )

    def save_model_to_hdfs(self, model: LinearRegressionModel, path: str = None):
        """
        Saves the trained machine learning model to HDFS. If no path is provided, uses the default model path from config.
        Args:
            model: The trained Spark MLlib model to save.
            path (str): HDFS path to save the model.
        """
        if path is None:
            path = Config.HDFS_MODEL_PATH + "model_lr"
        model.save(path)

    def write_to_hive(self, df, table_name: str = None, mode="overwrite"):
        """
        Writes a DataFrame to a Hive table. If no table name is provided, uses the default from config.
        Args:
            df (pyspark.sql.DataFrame): DataFrame to write to the Hive table.
            table_name (str): Target Hive table name.
            mode (str): Write mode, e.g., "overwrite" or "append". Default is "overwrite".
        """
        if table_name is None:
            table_name = Config.HIVE_TABLE_NAME
        try:
            df.write.mode(mode).saveAsTable(table_name)
            print(f"Data successfully written to Hive table: {table_name}")
        except Exception as e:
            print(f"Error writing to Hive table {table_name}: {e}")
            raise