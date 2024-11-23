from confluent_kafka import Consumer, KafkaException, KafkaError
import json
import time

# Configuration du consommateur
conf = {
    'bootstrap.servers': 'kafka:9092',
    'group.id': 'my-consumer-group',
    'auto.offset.reset': 'latest'
}

# Fonction pour créer un consommateur
def create_consumer():
    consumer = Consumer(conf)
    consumer.subscribe(['sensor-data'])  # S'abonner au topic sensor-data
    return consumer

# Fonction principale pour consommer les messages
def consume_messages(consumer):
    try:
        while True:
            msg = consumer.poll(timeout=1.0)  # Attendre les messages

            if msg is None:
                continue  # Aucun message reçu
            if msg.error():
                if msg.error().code() == KafkaError._PARTITION_EOF:
                    # Fin de la partition atteinte
                    print(f"End of partition reached {msg.partition()}")
                elif msg.error():
                    raise KafkaException(msg.error())
            else:
                # Message reçu
                print(f"Received message: {json.loads(msg.value().decode('utf-8'))}")

    except KeyboardInterrupt:
        # Interruption par l'utilisateur
        pass
    except KafkaException as e:
        print(f"Kafka exception: {e}")
        consumer.close()
        return False
    except Exception as e:
        print(f"Unexpected error: {e}")
        consumer.close()
        return False

    consumer.close()
    return True

# Boucle principale avec mécanisme de retry limité à 5 tentatives
max_retries = 5
retry_count = 0

while retry_count < max_retries:
    consumer = create_consumer()
    if consume_messages(consumer):
        break  # Sortir de la boucle si la consommation est terminée sans erreur
    retry_count += 1
    print(f"Reconnecting to Kafka in 5 seconds... (Attempt {retry_count}/{max_retries})")
    time.sleep(5)  # Attendre avant de réessayer de se connecter

if retry_count == max_retries:
    print("Max retries reached. Exiting.")