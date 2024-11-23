import pyspark.sql.functions as F 
from app.spark.common import TransformationBase

class Transformation(TransformationBase):
    PROCESS_NAME = "SparkApp2-DeltaProcessor"

    def read(self):
        self.source_df = self.reader.read_stream_from_kafka()

    def write(self):
        self.writer.write_stream_to_kafka(self.final_df)

    def transform(self):
         # Transformation pour obtenir la tension maximale
        self.final_df = (
            self.source_df.selectExpr("CAST(value AS STRING) as message")
            .withColumn("voltage", F.expr("CAST(split(message, ',')[1] AS DOUBLE)"))
            .withColumn("timestamp", F.current_timestamp())
            .groupBy(F.window("timestamp", "1 minute"))
            .agg(F.max("voltage").alias("max_voltage"))
            .selectExpr("CAST(max_voltage AS STRING) AS value")
        )

        print("Transformation réussie")


if __name__ == "__main__":
    app = Transformation()
    app.process_data()