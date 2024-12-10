import json
import pyspark.sql.functions as F
from app.spark.common import TransformationBase
from prometheus_client import start_http_server, Gauge
from confluent_kafka import Producer

# Démarrer le serveur Prometheus pour exposer les métriques
start_http_server(8001)

# Définir une métrique pour le maximum de voltage
max_voltage_metric = Gauge('spark_app1_max_voltage', 'Maximum voltage processed by SparkApp1')

# Configuration de Kafka Producer
kafka_conf = {
    'bootstrap.servers': 'kafka:9092',
    'client.id': 'spark-app1-producer'
}


class Transformation(TransformationBase):
    PROCESS_NAME = "SparkApp1-DeltaProcessor"

    def __init__(self):
        super().__init__()
        self.producer = Producer(kafka_conf)  # Initialiser le producteur Kafka

    def read(self):
        # Lire depuis Kafka en streaming
        self.source_df = self.reader.read_stream_from_kafka()

    def write(self):
        # Fonction pour envoyer les données à Kafka
        def send_to_kafka(batch_df, batch_id):
            try:
                for row in batch_df.collect():
                    message = {"max_voltage": row["max_voltage"], "window": str(row["window"])}
                    self.producer.produce(
                        topic='processed-voltage',
                        value=json.dumps(message).encode('utf-8')
                    )
                    self.producer.flush()
                    print(f"Message sent to Kafka: {message}")
            except Exception as e:
                print(f"Error sending message to Kafka: {e}")

        # Écrire les données transformées dans Kafka en batch
        self.final_df.writeStream.foreachBatch(send_to_kafka).start().awaitTermination()

    def transform(self):
        # Transformation pour obtenir la tension maximale
        self.final_df = (
            self.source_df.selectExpr("CAST(value AS STRING) as message")
            .withColumn("voltage", F.expr("CAST(split(message, ',')[1] AS DOUBLE)"))
            .withColumn("timestamp", F.current_timestamp())
            # Ajouter un watermark (5 minutes dans cet exemple)
            .withWatermark("timestamp", "5 minutes")
            .groupBy(F.window("timestamp", "1 minute"))
            .agg(F.max("voltage").alias("max_voltage"))
        )

        # Mettre à jour la métrique Prometheus
        def update_metrics(batch_df, batch_id):
            for row in batch_df.collect():
                max_voltage_metric.set(row["max_voltage"])
                print(f"Prometheus metric updated: max_voltage = {row['max_voltage']}")

        # Appliquer la mise à jour des métriques en batch
        self.final_df.writeStream.foreachBatch(update_metrics).start()

        print("Transformation réussie")


if __name__ == "__main__":
    app = Transformation()
    app.process_data()
