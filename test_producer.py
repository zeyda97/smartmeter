from confluent_kafka import Producer, KafkaException
import json
import time

# Configuration du producteur
conf = {
    'bootstrap.servers': 'kafka:9092'
}

# Fonction pour créer un producteur
def create_producer():
    return Producer(conf)

# Fonction pour envoyer un message
def send_message(producer, topic, key, value):
    try:
        producer.produce(topic, key=key, value=json.dumps(value).encode('utf-8'))
        producer.flush()
        print(f"Message sent to topic {topic}")
        return True
    except KafkaException as e:
        print(f"Kafka exception: {e}")
        return False
    except Exception as e:
        print(f"Unexpected error: {e}")
        return False

# Boucle principale avec mécanisme de retry limité à 5 tentatives
max_retries = 5
retry_count = 0

while retry_count < max_retries:
    producer = create_producer()
    if send_message(producer, 'your-topic', key=b'key1', value={'your': 'message'}):
        break  # Sortir de la boucle si l'envoi est réussi
    retry_count += 1
    print(f"Retrying connection in 5 seconds... (Attempt {retry_count}/{max_retries})")
    time.sleep(5)  # Attendre avant de réessayer de se connecter

if retry_count == max_retries:
    print("Max retries reached. Exiting.")