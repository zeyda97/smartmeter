import pyspark.sql.functions as F 
from app.spark.common import TransformationBase

class Transformation(TransformationBase):
    PROCESS_NAME = "SparkApp2-DeltaProcessor"

    

    def read(self):
        self.source_df = self.reader.read_stream_from_kafka()

    def write(self):
        self.writer.write_stream_to_delta(self.final_df)

    def transform(self):
        schema = "meter_id INT, voltage DOUBLE, timestamp DOUBLE"
        self.final_df = (
            self.source_df.selectExpr("CAST(value AS STRING)")
            .select(F.from_json(F.col("value"), schema).alias("data"))
            .select("data.*")
            .withColumn("processed_time", F.current_timestamp())
        )


if __name__ == "__main__":
    app = Transformation()
    app.process_data()