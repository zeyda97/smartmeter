FROM apache/hive:4.0.1

user root 

ENV POSTGRES_LOCAL_PATH=/opt/hive/jdbc/postgresql-42.7.4.jar

RUN apt-get update && \
    apt-get install -y wget curl && \
    wget https://jdbc.postgresql.org/download/postgresql-42.7.4.jar && \
    mv postgresql-42.7.4.jar /opt/hive/lib

RUN cd /opt/hive/conf && \
    cp hive-env.sh.template hive-env.sh && \
    chmod +x hive-env.sh

COPY ./src/infra/hive-config.xml /opt/hive/conf/hive-site.xml

RUN cd /opt/hive/conf && \
    chmod +x hive-site.xml