from airflow import DAG
from airflow.providers.apache.spark.operators.spark_submit import SparkSubmitOperator
from datetime import datetime, timedelta

default_args = {
    'owner': 'airflow',
    'start_date': datetime(2023, 1, 1),
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

dag = DAG('snsor_app_job1', default_args=default_args, schedule_interval=None)

# Tâche pour exécuter le job Spark 
spark_submit = SparkSubmitOperator(
    task_id='spark_submit_task',
    application='/opt/airflow/app/spark/jobs/spark_app1.py',
    conf={'spark.master': 'spark://spark-master:7077', 'spark.jars.ivy': '/opt/airflow', 'spark.sql.extensions': 'io.delta.sql.DeltaSparkSessionExtension', 'spark.sql.catalog.spark_catalog': 'org.apache.spark.sql.delta.catalog.DeltaCatalog'},
    conn_id='spark_default',
    packages='org.apache.spark:spark-sql-kafka-0-10_2.12:3.5.3,io.delta:delta-core_2.12:2.1.0',
    dag=dag,
)
