from app.spark.common.kafkaconfig import KafkaConfig
from app.spark.common.config import Config
from pyspark.sql import SparkSession

class Reader:
    def __init__(self, spark: SparkSession):
        self.spark = spark
        self.kafka_config = KafkaConfig()

    def read_stream_from_kafka(self):
        """
        Reads streaming data from Kafka topics.
        """
        return (
            self.spark
            .readStream
            .format("kafka")
            .option("kafka.bootstrap.servers", self.kafka_config.bootstrap_servers)
            .option("subscribe", self.kafka_config.input_topic)
            .option("startingOffsets", "latest")
            .load()
        )

    def read_data_from_hdfs(self, path: str = None):
        """
        Reads raw data from HDFS. If no path is provided, uses the default data lake path from config.
        Args:
            path (str): Path to the HDFS file or directory.

        Returns:
            pyspark.sql.DataFrame: A DataFrame containing the data from HDFS.
        """
        if path is None:
            path = Config.HDFS_DATA_LAKE_PATH
        return self.spark.read.format("parquet").load(path)

    def read_from_hive(self, table_name: str = None):
        """
        Reads data from a Hive table. If no table name is provided, uses the default from config.
        Args:
            table_name (str): Name of the Hive table to query.

        Returns:
            pyspark.sql.DataFrame: A DataFrame containing the data from the Hive table.
        """
        if table_name is None:
            table_name = Config.HIVE_TABLE_NAME
        try:
            return self.spark.sql(f"SELECT * FROM {table_name}")
        except Exception as e:
            print(f"Error reading Hive table {table_name}: {e}")
            raise