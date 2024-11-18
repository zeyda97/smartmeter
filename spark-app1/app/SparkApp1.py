from pyspark.sql import SparkSession

from KafkaConfig import KafkaConfig
from StreamingProcessor import StreamingProcessor


class SparkApp1:
    def __init__(self):
        self.spark = SparkSession.builder \
            .appName("SparkApp1 - Calculateur de Tension Maximale") \
            .master("spark://spark-master:7077") \
            .getOrCreate()

        self.kafka_config = KafkaConfig()
        self.processor = StreamingProcessor(self.spark, self.kafka_config)

    def run(self):
        self.processor.process_stream()


if __name__ == "__main__":
    app = SparkApp1()
    app.run()
