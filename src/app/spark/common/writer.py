from app.spark.common.kafkaconfig import KafkaConfig
from app.spark.common.deltaconfig import DeltaConfig
class Writer:
    def __init__(self):
        self.kafka_config = KafkaConfig()
        self.delta_config = DeltaConfig()

    def write_stream_to_kafka(self, df):
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
    
    def write_stream_to_delta(self, df):
        return (
            df.writeStream
            .format("delta")
            .option("path", self.delta_config.hdfs_output)
            .option("checkpointLocation", self.delta_config.checkpoint_location)
            .outputMode("complete")
            .trigger(processingTime="1 minute")
            .start()
            .awaitTermination()
        )

