FROM openjdk:8-jdk-slim

# Install system dependencies
RUN apt-get update && apt-get install -y curl software-properties-common && \
    apt-get clean

# Download and extract Apache Spark
RUN curl -fsSL https://archive.apache.org/dist/spark/spark-3.4.1/spark-3.4.1-bin-hadoop3.tgz | \
    tar -xz -C /opt && \
    mv /opt/spark-3.4.1-bin-hadoop3 /opt/spark

# Set Spark environment variables
ENV SPARK_HOME=/opt/spark
ENV PATH=$SPARK_HOME/bin:$PATH

# Set the working directory
WORKDIR /app

# Copy application files
COPY app/ /app

# Copy the requirements file
COPY requirements.txt /app/requirements.txt

# Install Python dependencies
RUN apt-get install -y python3 python3-pip && \
    pip3 install -r /app/requirements.txt

# Default command for running Spark applications
CMD ["spark-submit", "--packages", "org.apache.spark:spark-sql-kafka-0-10_2.12:3.4.1", "/app/spark_app2.py"]