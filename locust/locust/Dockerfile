# Utiliser une image Python "slim" comme base
FROM python:3.9-slim

# Mettre à jour pip et installer les dépendances système et Python
RUN apt-get update && apt-get install -y gcc libffi-dev libev-dev build-essential && \
    pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir locust kafka-python

# Copier le fichier Locust
COPY ./locust/smart_meter_locustfile.py /locust/

# Définir le répertoire de travail
WORKDIR /locust

# Exposer le port par défaut de Locust
EXPOSE 8089

# Commande par défaut pour exécuter Locust
CMD ["locust", "-f", "smart_meter_locustfile.py"]
