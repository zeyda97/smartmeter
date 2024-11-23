FROM locustio/locust:latest


RUN pip install confluent_kafka locust

WORKDIR /mnt/locust

# Copy the locustfile.py into the container
COPY ./src/app/locust/smart_meter_locustfile.py /mnt/locust/smart_meter_locustfile.py

# Set the entrypoint to locust
ENTRYPOINT ["locust"]