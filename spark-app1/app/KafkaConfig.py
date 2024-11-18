class KafkaConfig:
    def __init__(self):
        self.bootstrap_servers = "kafka:9092"
        self.input_topic = "sensor-data"
        self.output_topic = "max_voltage_topic"
        self.checkpoint_location = "/tmp/spark-app1-checkpoint"
