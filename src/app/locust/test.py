import random
from datetime import datetime, timezone
from locust import HttpUser, TaskSet, task, between
from confluent_kafka import Producer
import json
from interpolateProfile import InterpolatedProfileByUsagePoint
from temperatureProvider import TemperatureProvider
from timeProvider import TimeProvider
from valueProvider import ConsumerInterpolatedVoltageProvider

class SmartMeterBehavior(TaskSet):
    def on_start(self):
        """Initialisation avant le début de la simulation."""
        self.slot = 1  # Identifiant fictif de slot pour chaque utilisateur
        self.users_per_sec = 100  # Paramètre arbitraire pour le débit
        self.streaming_duration = 60  # Durée de streaming en secondes
        self.randomness = 0.5  # Facteur de variation aléatoire
        self.prediction_length = 12  # Longueur de la prévision
        
        # Initialisation des fournisseurs
        self.voltage_provider = ConsumerInterpolatedVoltageProvider(
            slot=self.slot,
            users_per_sec=self.users_per_sec,
            streaming_duration=self.streaming_duration,
            randomness=self.randomness,
            prediction_length=self.prediction_length,
        )
        self.profile_provider = InterpolatedProfileByUsagePoint()
        self.time_provider = TimeProvider()

        # Initialisation du Kafka Producer avec Confluent Kafka
        self.producer_conf = {
            'bootstrap.servers': 'kafka:9092',  # Remplacez par l'adresse de votre broker Kafka
            'client.id': 'smart-meter-client'
        }
        self.producer = Producer(self.producer_conf)

    def on_stop(self):
        """Méthode appelée à la fin de chaque utilisateur pour fermer la connexion Kafka"""
        self.producer.flush()

    @task(2)
    def send_temperature_data(self):
        """Envoie des données de température simulées à Kafka."""
        subject = self.voltage_provider.get_subject()
        if subject == ".temperature.data":
            payload = self.voltage_provider.get_payload()
            # Envoie les données au topic Kafka "temperature_data"
            self.producer.produce('temperature_data', value={'type': 'temperature', 'data': payload})
            print(f"Temperature data sent: {payload}")

    @task(2)
    def send_voltage_data(self):
        """Envoie des données de tension simulées à Kafka."""
        subject = self.voltage_provider.get_subject()
        if ".voltage.data" in subject:
            payload = self.voltage_provider.get_payload()
            # Envoie les données au topic Kafka "voltage_data"
            self.producer.produce('voltage_data', value={'type': 'voltage', 'data': payload})
            print(f"Voltage data sent: {payload}")

    @task(1)
    def get_forecast(self):
        """Simule la récupération de prévisions et envoie à Kafka."""
        subject = self.voltage_provider.get_subject()
        if subject == ".temperature.forecast.12":
            payload = self.voltage_provider.get_payload()
            # Envoie les données de prévisions au topic Kafka "forecast_data"
            self.producer.produce('forecast_data', value={'type': 'forecast', 'data': payload})
            print(f"Forecast data sent: {payload}")

class KafkaUser(HttpUser):
    tasks = [SmartMeterBehavior]
    wait_time = between(1, 3)  # Temps d'attente entre les tâches (1 à 3 secondes)
