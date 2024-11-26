from pyspark.sql import SparkSession
from pyspark.ml.regression import LinearRegression
from common.writer import Writer
from common.utilities import Utilities

def main():
    # Initialize Spark Session with Hive support
    spark = SparkSession.builder \
        .appName("Spark_App4") \
        .enableHiveSupport() \
        .getOrCreate()

    # Initialize Writer and Utilities instances
    writer = Writer()
    utils = Utilities()

    # Step 1: Read raw data from Hive table
    hive_table_name = "default.ddd"  # Replace with your Hive table name
    print(f"Reading data from Hive table: {hive_table_name}")

    try:
        raw_data = spark.sql(f"SELECT * FROM {hive_table_name}")
    except Exception as e:
        print(f"Error reading Hive table: {e}")
        return

    # Step 2: Preprocess data
    feature_columns = ["voltage", "timestamp", "processed_time"]  # Replace with actual feature columns
    label_column = "meter_id"  # Replace with the actual label column name
    data = utils.preprocess_data(raw_data, feature_columns, label_column)
    
    if data is None:
        print("Data preprocessing failed. Exiting.")
        return

    # Step 3: Train-Test Split
    train_data, test_data = data.randomSplit([0.8, 0.2], seed=123)

    # Step 4: Train the model
    print("Training the model...")
    lr = LinearRegression(featuresCol="features", labelCol=label_column)
    lr_model = lr.fit(train_data)

    # Step 5: Evaluate the model
    metrics = {
        "rmse": lr_model.summary.rootMeanSquaredError,
        "r2": lr_model.summary.r2
    }
    print(f"Model Evaluation: RMSE = {metrics['rmse']}, R2 = {metrics['r2']}")

    # Step 6: Log model and metrics to MLflow
    experiment_name = "Voltage Prediction"
    params = {"algorithm": "LinearRegression"}
    utils.log_model_to_mlflow(lr_model, experiment_name, metrics, params)

    # Step 7: Save predictions to Delta Lake (or HDFS)
    predictions = lr_model.transform(test_data)
    writer.write_stream_to_delta(predictions)

    # Step 8: Save the trained model to HDFS
    model_save_path = "hdfs://namenode:9000/user/hive/warehouse/model_lr"  # Update with your desired HDFS path
    writer.save_model_to_hdfs(lr_model, model_save_path)

    print("Spark App4 completed successfully!")

if __name__ == "__main__":
    main()