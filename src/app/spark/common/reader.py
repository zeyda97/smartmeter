from app.spark.common.kafkaconfig import KafkaConfig
class Reader:
    def __init__(self, spark):
        self.spark = spark
        self.kafka_config = KafkaConfig()

    def read_stream_from_kafka(self):
        return (
            self.spark
            .readStream
            .format("kafka")
            .option("kafka.bootstrap.servers", self.kafka_config.bootstrap_servers)
            .option("subscribe", self.kafka_config.input_topic)
            .option("startingOffsets", "latest")
            .load()
        )
