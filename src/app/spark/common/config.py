class Config:
    # HDFS Configuration
    HDFS_DATA_LAKE_PATH = "hdfs://namenode:9000/user/hive/warehouse/"
    HDFS_MODEL_PATH = "hdfs://namenode:9000/user/models/"

    # Hive Configuration
    HIVE_TABLE_NAME = "default.ddd"

    # MLflow Configuration
    MLFLOW_TRACKING_URI = "http://localhost:5000"
    EXPERIMENT_NAME = "Voltage Prediction"