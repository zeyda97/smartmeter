FROM locustio/locust:latest


RUN pip install confluent_kafka locust numpy scipy plotly prometheus_client

WORKDIR /mnt/locust

# Set the entrypoint to locust
ENTRYPOINT ["locust", "-f", "/mnt/locust/smart_meter_locustfile.py"]