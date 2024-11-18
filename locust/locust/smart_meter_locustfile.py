from locust import HttpUser, task, between
from kafka import KafkaProducer
import json
import random
import time

class SmartMeterUser(HttpUser):
    wait_time = between(1, 5)

    def on_start(self):
        """Méthode appelée au début de chaque utilisateur pour initialiser le producteur Kafka"""
        self.producer = KafkaProducer(
            bootstrap_servers=['kafka:9092'],
            value_serializer=lambda v: json.dumps(v).encode('utf-8')
        )

    def on_stop(self):
        """Méthode appelée à la fin de chaque utilisateur pour fermer la connexion Kafka"""
        self.producer.close()

    @task
    def send_smart_meter_data(self):
        """Simule l'envoi de données de compteur intelligent à Kafka"""
        data = {
            "meter_id": random.randint(1, 1000),
            "voltage": round(random.uniform(110, 120), 2),
            "timestamp": time.time()
        }
        # Envoi des données au topic Kafka 'smart_meter_data'
        self.producer.send('smart_meter_data', value=data)
        print(f"Data sent to Kafka: {data}")
