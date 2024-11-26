import json
from pyspark.ml.feature import VectorAssembler
import mlflow
import mlflow.spark
from app.spark.common.config import Config

class Utilities:
    def parse_kafka_message(self, value):
        """
        Helper function to parse Kafka JSON message.
        """
        try:
            return json.loads(value.decode("utf-8"))
        except Exception as e:
            print(f"Error parsing Kafka message: {e}")
            return None

    def preprocess_data(self, raw_data, feature_columns, label_column):
        """
        Prepares data for machine learning by assembling features.
        Args:
            raw_data (pyspark.sql.DataFrame): Input raw data.
            feature_columns (list): List of feature column names.
            label_column (str): Name of the label column.
        
        Returns:
            pyspark.sql.DataFrame: Transformed DataFrame with 'features' and 'label'.
        """
        for col in feature_columns + [label_column]:
            if col not in raw_data.columns:
                raise ValueError(f"Column '{col}' not found in input data.")
        
        assembler = VectorAssembler(inputCols=feature_columns, outputCol="features")
        try:
            processed_data = assembler.transform(raw_data).select("features", label_column)
            return processed_data
        except Exception as e:
            print(f"Error in preprocessing data: {e}")
            return None

    def log_model_to_mlflow(self, model, experiment_name=None, metrics=None, params=None):
        """
        Logs the trained model and metadata to MLflow. Defaults to config constants if not provided.
        Args:
            model: Trained machine learning model.
            experiment_name (str): MLflow experiment name.
            metrics (dict): Dictionary of evaluation metrics.
            params (dict): Dictionary of model parameters.
        """
        if experiment_name is None:
            experiment_name = Config.EXPERIMENT_NAME
        if metrics is None:
            metrics = {}
        if params is None:
            params = {}

        try:
            mlflow.set_tracking_uri(Config.MLFLOW_TRACKING_URI)
            mlflow.set_experiment(experiment_name)
            with mlflow.start_run():
                # Log the model to MLflow
                mlflow.spark.log_model(model, "model")
                
                # Log metrics
                for metric, value in metrics.items():
                    mlflow.log_metric(metric, value)
                
                # Log parameters
                for param, value in params.items():
                    mlflow.log_param(param, value)
                
                print(f"Model logged to MLflow under experiment: {experiment_name}")
        except Exception as e:
            print(f"Error logging model to MLflow: {e}")