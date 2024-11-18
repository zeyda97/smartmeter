# Utiliser l'image officielle Spark comme base
FROM bitnami/spark:latest

# Définir les variables d'environnement
ENV HADOOP_HOME=/opt/bitnami/hadoop
ENV SPARK_HOME=/opt/bitnami/spark
ENV IVY_HOME=/root/.ivy2
ENV PYTHONPATH=/poc-spark-app1


# Créer un répertoire pour l'application
WORKDIR /app

# Copier le script Python dans le conteneur
COPY app/ /app/

# Définir l'URL du master Spark
ENV SPARK_MASTER_URL=spark://spark-master:7077

# Exécuter l'application Spark
ENTRYPOINT ["spark-submit", "--conf", "spark.jars.ivy=/root/.ivy2", "/app/SparkApp1.py"]
