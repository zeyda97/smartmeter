FROM postgres:13.0
USER root
COPY ./src/infra/postgres-init-db.sh /postgres-init-db.sh
RUN chmod +x /postgres-init-db.sh