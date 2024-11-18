FROM locustio/locust:latest

# Copy the requirements.txt file into the container
COPY requirements.txt /tmp/requirements.txt

# Install the dependencies
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# Copy the locustfile.py into the container
COPY smart_meter_locustfile.py /mnt/locust/smart_meter_locustfile.py

# Set the entrypoint to locust
ENTRYPOINT ["locust"]