from pyspark.sql import SparkSession

# Initialize Spark session with Hive support
spark = SparkSession.builder \
    .appName("CreateHiveTable") \
    .enableHiveSupport() \
    .getOrCreate()

query = """
CREATE EXTERNAL TABLE IF NOT EXISTS ddd 
( meter_id INT,
    voltage DOUBLE,
    timestamp DOUBLE,
    processed_time timestamp) 
    STORED AS PARQUET 
    LOCATION 'hdfs://namenode:9000/user/hive/warehouse/ddd'
"""

# Exécuter la commande CREATE TABLE

spark.sql(query)

spark.sql("SELECT * FROM default.ddd").show()

print('######### SHOW TABLES AFTER INSERTION #########')

# # Exécuter la commande DESCRIBE TABLE
describe_df = spark.sql(f"DESCRIBE EXTENDED default.ddd")

# Afficher les résultats de la commande DESCRIBE TABLE
print(describe_df.collect())