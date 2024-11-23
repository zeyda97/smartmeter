class Utilities:

    def parse_kafka_message(self, value):
        """
        Helper function to parse Kafka JSON message
        """
        import json
        try:
            return json.loads(value.decode("utf-8"))
        except Exception as e:
            print(f"Error parsing Kafka message: {e}")
            return None