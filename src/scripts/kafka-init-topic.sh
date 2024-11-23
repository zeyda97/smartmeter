#!/bin/bash

# Function to check if Kafka is running
check_kafka() {
  nc -z kafka 9092
  return $?
}

# Wait for Kafka to be ready
echo "Waiting for Kafka to start..."
while ! check_kafka; do
    sleep 10
done

echo "Kafka is up and running."

# Create a default topic
kafka-topics --create --topic sensor-data --bootstrap-server kafka:9092 --partitions 3 --replication-factor 1

echo "Topic 'sensor-data' created."