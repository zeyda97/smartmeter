from dataclasses import dataclass
from abc import abstractmethod
from pyspark.sql import SparkSession, DataFrame
from app.spark.common.reader import Reader
from app.spark.common.writer import Writer


@dataclass
class TransformationBase:

    spark: SparkSession | SparkSession.getActiveSession() | None = None
    PROCESS_NAME: str = ""
    source_df: DataFrame | None = None
    final_df: DataFrame | None = None
    
    def __post_init__(self):
        if self.spark is None:
            print("Creating a new SparkSession")
            self.spark = (
                SparkSession.builder
                .appName(self.PROCESS_NAME)
                .master("spark://spark-master:7077")
                .enableHiveSupport()
                .getOrCreate()
            )
        self.reader = Reader(self.spark)
        self.writer = Writer()
        
    @abstractmethod
    def transform(self):
        raise NotImplementedError("transform method must be implemented")
    
    @abstractmethod
    def read(self):
        raise NotImplementedError("read method must be implemented")
    
    @abstractmethod
    def write(self):
        raise NotImplementedError("write method must be implemented")
    
    def process_data(self):
        try:
            self.read()
            self.transform()
            self.write()
        except Exception as ex:
            print("An error occurred while processing the stream:", str(ex))
            raise ex