FROM locustio/locust:latest


RUN pip install confluent_kafka locust numpy scipy

WORKDIR /mnt/locust

# Set the entrypoint to locust
ENTRYPOINT ["locust"]