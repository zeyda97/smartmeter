#!/bin/bash

# Variables
HIVE_USER="hive"
HIVE_PASSWORD="hive"
HIVE_DATABASE="hivemetastore"

AIRFLOW_USER="airflow"
AIRFLOW_PASSWORD="airflow"
AIRFLOW_DATABASE="airflow"

ADMIN_USER="postgres"
ADMIN_PASSWORD="admin"

# Connect to PostgreSQL and run commands
psql -U $ADMIN_USER <<EOF
-- Create hive user with all privileges
CREATE USER $HIVE_USER WITH PASSWORD '$HIVE_PASSWORD';
ALTER USER $HIVE_USER WITH SUPERUSER;

# -- Create airflow user with all privileges
# CREATE USER $AIRFLOW_USER WITH PASSWORD '$AIRFLOW_PASSWORD';
# ALTER USER $AIRFLOW_USER WITH SUPERUSER;

# -- Create new database
# CREATE DATABASE $HIVE_DATABASE;

# -- Grant all privileges on the new database to the new user
# GRANT ALL PRIVILEGES ON DATABASE $HIVE_DATABASE TO $HIVE_USER;

# -- Create new database
# CREATE DATABASE $AIRFLOW_DATABASE;

# -- Grant all privileges on the new database to the new user
# GRANT ALL PRIVILEGES ON DATABASE $AIRFLOW_DATABASE TO $AIRFLOW_USER;
EOF

echo "User and database created successfully."
