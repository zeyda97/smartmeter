from locust import HttpUser, task, between
from confluent_kafka import Producer
import json
import random
import time

class KafkaUser(HttpUser):
    wait_time = between(1, 5)  # Temps d'attente entre les tâches (1 à 5 secondes)

    def on_start(self):
        # Configuration du producteur Kafka
        self.producer_conf = {
            'bootstrap.servers': 'kafka:9092'
        }
        self.producer = Producer(self.producer_conf)

    def on_stop(self):
        """Méthode appelée à la fin de chaque utilisateur pour fermer la connexion Kafka"""
        self.producer.close()

    @task
    def send_smart_meter_data(self):
        """Simule l'envoi de données de compteur intelligent à Kafka"""
        try:
            # Message à envoyer
            data = {
                "meter_id": random.randint(1, 1000),
                "voltage": round(random.uniform(110, 120), 2),
                "timestamp": time.time()
            }
            self.producer.produce('sensor-data', key=f"{data['meter_id']}", value=json.dumps(data).encode('utf-8'))
            self.producer.flush()
            print("Message sent to Kafka")
        except Exception as e:
            print(f"Failed to send message: {e}")
