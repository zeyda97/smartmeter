from pyspark.sql.functions import expr, current_timestamp, window, max

class StreamingProcessor:
    def __init__(self, spark, kafka_config):
        self.spark = spark
        self.kafka_config = kafka_config

    def process_stream(self):
        try:
            print("Configuration Kafka :")
            print(f"Bootstrap Servers: {self.kafka_config.bootstrap_servers}")
            print(f"Input Topic: {self.kafka_config.input_topic}")

            # Lire les données de Kafka
            kafka_df = self.spark.readStream \
                .format("kafka") \
                .option("kafka.bootstrap.servers", self.kafka_config.bootstrap_servers) \
                .option("subscribe", self.kafka_config.input_topic) \
                .option("startingOffsets", "latest") \
                .load()

            print("Lecture des données Kafka réussie")

            # Transformation pour obtenir la tension maximale
            voltage_df = kafka_df.selectExpr("CAST(value AS STRING) as message") \
                .withColumn("voltage", expr("CAST(split(message, ',')[1] AS DOUBLE)")) \
                .withColumn("timestamp", current_timestamp()) \
                .groupBy(window("timestamp", "1 minute")) \
                .agg(max("voltage").alias("max_voltage"))

            print("Transformation réussie")

            # Écrire les résultats à Kafka
            query = voltage_df.selectExpr("CAST(max_voltage AS STRING) AS value") \
                .writeStream \
                .format("kafka") \
                .option("kafka.bootstrap.servers", self.kafka_config.bootstrap_servers) \
                .option("topic", self.kafka_config.output_topic) \
                .option("checkpointLocation", self.kafka_config.checkpoint_location) \
                .trigger(processingTime="1 minute") \
                .start()

            print("Écriture dans Kafka réussie")
            query.awaitTermination()

        except Exception as e:
            print("Une erreur est survenue lors du traitement du flux :", str(e))
            raise e
