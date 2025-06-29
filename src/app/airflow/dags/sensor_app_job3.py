from airflow import DAG
from airflow.providers.apache.spark.operators.spark_submit import SparkSubmitOperator
from datetime import datetime, timedelta

default_args = {
    'owner': 'airflow',
    'start_date': datetime(2023, 1, 1),
}

dag = DAG('sensor_app_job3', default_args=default_args, schedule_interval=None)

# Tâche pour exécuter le job Spark 
spark_submit = SparkSubmitOperator(
    task_id='spark_submit_task',
    application='/opt/airflow/app/spark/jobs/spark_app3.py',
    conf={
        'spark.master': 'spark://spark-master:7077',
        'spark.jars.ivy': '/opt/airflow',
        'spark.sql.extensions': 'io.delta.sql.DeltaSparkSessionExtension',
        'spark.sql.catalog.spark_catalog': 'org.apache.spark.sql.delta.catalog.DeltaCatalog',
        'hive.metastore.uris':'thrift://hive-metastore:9083',
        'spark.sql.warehouse.dir': 'hdfs://namenode:9000/user/hive/warehouse',
        'spark.dynamicAllocation.minExecutors': '1',
        'spark.dynamicAllocation.maxExecutors': '5',
        'spark.executor.cores': '1',
        'spark.executor.memory': '500m',
        'spark.dynamicAllocation.enabled': 'true',
    },
    conn_id='spark_default',
    packages='org.apache.spark:spark-sql-kafka-0-10_2.12:3.5.3,io.delta:delta-core_2.12:2.1.0',
    dag=dag,
)
