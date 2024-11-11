#!/bin/bash

#echo
#echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"

replicas=1
postfix=""
shift_nb=0

while getopts ":r:l:m:p:" opt; do
  case $opt in
    r) replicas="$OPTARG"
     echo "replicas: $replicas"
    ((shift_nb+=2))
    ;;
    l) location="$OPTARG"
    # echo "location: $location"
    ((shift_nb+=2))
    ;;
    m) cluster_mode="$OPTARG"
    # echo "cluster_mode: $cluster_mode"
    ((shift_nb+=2))
    ;;
    p) postfix="$OPTARG"
    # echo "postfix: $postfix"
    ((shift_nb+=2))
    ;;
    \?) echo "Invalid option $OPTARG"
    ((shift_nb+=1))
    ;;
  esac
done

shift $shift_nb

# source the properties:
# https://coderanch.com/t/419731/read-properties-file-script
source properties/configuration.properties
source "properties/configuration-location-${location}.properties"
source "properties/configuration-location-${location}-debug.properties"
source "properties/configuration-mode-${cluster_mode}.properties"
source "properties/configuration-mode-${cluster_mode}-debug.properties"

stop_all() {
  docker ${remote} service rm $(docker ${remote} service ls -q)
  docker ${remote} stop $(docker ${remote} ps | grep -v -e aws -e grafana| cut -d ' ' -f 1)
}

create_network() {
  docker ${remote} network create --driver overlay --attachable smartmeter
#docker ${remote} service rm $(docker ${remote} service ls -q)
}

### DOCKER VISUALIZER ###

# https://github.com/dockersamples/docker-swarm-visualizer
create_service_visualizer() {
  cmd="docker ${remote} service create \
    --name visualizer \
    --network smartmeter \
    ${ON_MASTER_NODE} \
    -p 8080:8080/tcp \
    --mount=type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
    dockersamples/visualizer"
  echo "-----------------------------------------------------------------"
  echo "$cmd"
  echo "-----------------------------------------------------------------"
  eval $cmd
}

### Cassandra ###

create_volume_cassandra() {
  if [ "${postfix}" == "-remote" ]
  then
    cassandra_size=$CASSANDRA_REMOTE_VOLUME_SIZE
  elif [[ "${postfix}" == "-local" ]]; then
    cassandra_size=$CASSANDRA_LOCAL_VOLUME_SIZE
  else
    cassandra_size=$CASSANDRA_DEFAULT_VOLUME_SIZE
  fi

  cmd="docker ${remote} volume create --name cassandra-volume-1"
  echo "-----------------------------------------------------------------"
  echo "$cmd"
  echo "-----------------------------------------------------------------"
  eval $cmd
#  docker ${remote} volume create --name cassandra-volume-2 --opt o=size=$cassandra_size
#  docker ${remote} volume create --name cassandra-volume-3 --opt o=size=$cassandra_size
}

create_cluster_cassandra() {
docker-compose ${remote} -f docker-cassandra-compose.yml up -d
}

kill_cluster_cassandra() {
docker-compose ${remote} -f docker-cassandra-compose.yml down
}

# Deprecated
__call_cassandra_cql() {
  until docker ${remote} exec -it $(docker ${remote} ps | grep "${CASSANDRA_MAIN_NAME}" | rev | cut -d' ' -f1 | rev) cqlsh -e \
      "CREATE KEYSPACE IF NOT EXISTS $CASSANDRA_KEYSPACE_NAME WITH REPLICATION = $CASSANDRA_KEYSPACE_REPLICATION"; do
    echo "Try again to create keyspace"; sleep 4;
  done
  docker ${remote} exec -it $(docker ${remote} ps | grep "${CASSANDRA_MAIN_NAME}" | rev | cut -d' ' -f1 | rev) cqlsh -f "$1"
  # docker ${remote} run ${DOCKER_RESTART_POLICY} --net=smartmeter logimethods/smart-meter:cassandra sh -c 'exec cqlsh "cassandra-1" -f "$1"'
}

run_cassandra() {
  cmd="docker ${remote} run -d ${DOCKER_RESTART_POLICY} \
    --name ${CASSANDRA_MAIN_NAME} \
    --network smartmeter \
    ${EUREKA_WAITER_PARAMS_RUN} \
    -p 8778:8778 \
    -p ${CASSANDRA_COUNT_PORT}:6161 \
    -e LOCAL_JMX=no \
    -e CASSANDRA_SETUP_FILE=${CASSANDRA_SETUP_FILE} \
    -e CASSANDRA_COUNT_PORT=${CASSANDRA_COUNT_PORT}
    logimethods/smart-meter:cassandra${postfix}"
##    -v cassandra-volume-1:/var/lib/cassandra \
  echo "-----------------------------------------------------------------"
  echo "$cmd"
  echo "-----------------------------------------------------------------"
  eval $cmd
}

create_service_cassandra_single() {
  # https://hub.docker.com/_/cassandra/
  # http://serverfault.com/questions/806649/docker-swarm-and-volumes
  # https://clusterhq.com/2016/03/09/fun-with-swarm-part1/
  # https://github.com/Yannael/kafka-sparkstreaming-cassandra-swarm/blob/master/service-management/start-cassandra-services.sh

  cmd="docker ${remote} service create \
    --name ${CASSANDRA_MAIN_NAME} \
    --network smartmeter \
    ${ON_MASTER_NODE} \
    -e LOCAL_JMX=no \
    -e CASSANDRA_SETUP_FILE=${CASSANDRA_SETUP_FILE}
    -e CASSANDRA_COUNT_PORT=${CASSANDRA_COUNT_PORT}
    logimethods/smart-meter:cassandra${postfix}"
  echo "-----------------------------------------------------------------"
  echo "$cmd"
  echo "-----------------------------------------------------------------"
  eval $cmd
}

create_service_cassandra() {
  # https://hub.docker.com/_/cassandra/
  # http://serverfault.com/questions/806649/docker-swarm-and-volumes
  # https://clusterhq.com/2016/03/09/fun-with-swarm-part1/
  # https://github.com/Yannael/kafka-sparkstreaming-cassandra-swarm/blob/master/service-management/start-cassandra-services.sh

  cmd="docker ${remote} service create \
    --name ${CASSANDRA_MAIN_NAME} \
    --network smartmeter \
    ${ON_MASTER_NODE} \
    -e LOCAL_JMX=no \
    -e CASSANDRA_SETUP_FILE=${CASSANDRA_SETUP_FILE} \
    -e CASSANDRA_COUNT_PORT=${CASSANDRA_COUNT_PORT}
    logimethods/smart-meter:cassandra${postfix}"
  echo "-----------------------------------------------------------------"
  echo "$cmd"
  echo "-----------------------------------------------------------------"
  eval $cmd

  #Need to sleep a bit so IP can be retrieved below
#  while [[ -z $(docker ${remote} service ls |grep ${CASSANDRA_MAIN_NAME}| grep 1/1) ]]; do
#    echo Waiting for Cassandra seed service to start...
#    sleep 2
#    done;

#  export CASSANDRA_SEED="$(docker ${remote} ps |grep ${CASSANDRA_MAIN_NAME}|cut -d ' ' -f 1)"
#  echo "CASSANDRA_SEED: $CASSANDRA_SEED"

  cmd="docker ${remote} service create \
    --name ${CASSANDRA_NODE_NAME} \
    --network smartmeter \
    -e READY_WHEN="" \
    -e DEPENDS_ON=${CASSANDRA_MAIN_NAME} \
    --mode global \
    ${ON_WORKER_NODE} \
    -e LOCAL_JMX=no \
    -e SETUP_LOCAL_CONTAINERS=true \
    -e PROVIDED_CASSANDRA_SEEDS=\\\${${CASSANDRA_MAIN_NAME}_local} \
    logimethods/smart-meter:cassandra${postfix}"
  echo "-----------------------------------------------------------------"
  echo "$cmd"
  echo "-----------------------------------------------------------------"
  eval $cmd
}

__create_full_service_cassandra() {
  # https://hub.docker.com/_/cassandra/
  # http://serverfault.com/questions/806649/docker-swarm-and-volumes
  # https://clusterhq.com/2016/03/09/fun-with-swarm-part1/
  cmd="docker ${remote} service create \
    --name ${CASSANDRA_MAIN_NAME} \
    --network smartmeter \
    --mount type=volume,source=cassandra-volume-1,destination=/var/lib/cassandra \
    ${ON_MASTER_NODE} \
    -e CASSANDRA_BROADCAST_ADDRESS="cassandra" \
    -e CASSANDRA_CLUSTER_NAME="Smartmeter Cluster" \
    -p 9042:9042 \
    -p 9160:9160 \
    logimethods/smart-meter:cassandra${postfix}"
  echo "-----------------------------------------------------------------"
  echo "$cmd"
  echo "-----------------------------------------------------------------"
  eval $cmd
}

create_service_hadoop() {
  # READY_WHEN="\'starting nodemanager\""
  cmd="docker ${remote} service create \
    --name ${HADOOP_NAME} \
    --network smartmeter \
    ${ON_MASTER_NODE} \
    -p 50070:50070 \
    sequenceiq/hadoop-docker:${hadoop_docker_version}"
  echo "-----------------------------------------------------------------"
  echo "$cmd"
  echo "-----------------------------------------------------------------"
  eval $cmd
}

create_service_spark-master() {
  cmd="docker ${remote} service create \
    --name ${SPARK_MASTER_NAME} \
    -e SERVICE_NAME=${SPARK_MASTER_NAME} \
    --network smartmeter \
    --replicas=${replicas} \
    -p ${SPARK_UI_PORT}:8080 \
    ${ON_MASTER_NODE} \
    ${spark_image}:${spark_version}-hadoop-${hadoop_version}"
  echo "-----------------------------------------------------------------"
  echo "$cmd"
  echo "-----------------------------------------------------------------"
  eval $cmd
}

create_service_spark-slave() {
  cmd="docker ${remote} service create \
    --name ${SPARK_WORKER_NAME} \
    -e SERVICE_NAME=spark-slave \
    --network smartmeter \
    --mode global \
    ${ON_WORKER_NODE} \
    ${spark_image}:${spark_version}-hadoop-${hadoop_version} \
      bin/spark-class org.apache.spark.deploy.worker.Worker spark://${SPARK_MASTER_NAME}:7077"
  echo "-----------------------------------------------------------------"
  echo "$cmd"
  echo "-----------------------------------------------------------------"
  eval $cmd
}

run_spark_autoscaling() {
  cmd="docker ${remote} run -d ${DOCKER_RESTART_POLICY} \
    -v /var/run/docker.sock:/var/run/docker.sock \
    --name spark_autoscaling \
    --network smartmeter \
    logimethods/spark-autoscaling python3 autoscale_sh.py"
#    --log-driver=json-file \
  echo "-----------------------------------------------------------------"
  echo "$cmd"
  echo "-----------------------------------------------------------------"
  eval $cmd
}

### Create Service ###

create_secrets_nats() {
  docker secret create nats_username_secret ./devsecrets/nats_username_secret
  docker secret create nats_password_secret ./devsecrets/nats_password_secret
  docker secret create nats_cluster_username_secret ./devsecrets/nats_cluster_username_secret
  docker secret create nats_cluster_password_secret ./devsecrets/nats_cluster_password_secret
}

create_service_nats() {
  cmd="docker ${remote} service create \
      --name $NATS_NAME \
      --network smartmeter \
      ${ON_MASTER_NODE} \
      ${EUREKA_WAITER_PARAMS_SERVICE} \
      -e READY_WHEN=\"Server is ready\" \
      -e NATS_USERNAME_FILE=/run/secrets/nats_username_secret \
      -e NATS_PASSWORD_FILE=/run/secrets/nats_password_secret \
      -e NATS_CLUSTER_USERNAME_FILE=/run/secrets/nats_cluster_username_secret \
      -e NATS_CLUSTER_PASSWORD_FILE=/run/secrets/nats_cluster_password_secret \
      -p 4222:4222 \
      -p 8222:8222 \
      --secret nats_username_secret \
      --secret nats_password_secret \
      --secret nats_cluster_username_secret \
      --secret nats_cluster_password_secret \
      logimethods/smart-meter:nats-server${postfix} \
        /gnatsd -c gnatsd.conf -m 8222 ${NATS_DEBUG} -cluster nats://0.0.0.0:6222"
  echo "-----------------------------------------------------------------"
  echo "$cmd"
  echo "-----------------------------------------------------------------"
  eval $cmd

  cmd="docker ${remote} service create \
      --name $NATS_CLUSTER_NAME \
      --network smartmeter \
      --mode global \
      ${ON_WORKER_NODE} \
      ${EUREKA_WAITER_PARAMS_SERVICE} \
      -e READY_WHEN=\"Server is ready\" \
      -e NATS_USERNAME_FILE=/run/secrets/nats_username_secret \
      -e NATS_PASSWORD_FILE=/run/secrets/nats_password_secret \
      -e NATS_CLUSTER_USERNAME_FILE=/run/secrets/nats_cluster_username_secret \
      -e NATS_CLUSTER_PASSWORD_FILE=/run/secrets/nats_cluster_password_secret \
      --secret nats_username_secret \
      --secret nats_password_secret \
      --secret nats_cluster_username_secret \
      --secret nats_cluster_password_secret \
      logimethods/smart-meter:nats-server${postfix} \
        /gnatsd -c gnatsd.conf -m 8222 ${NATS_DEBUG} -cluster nats://0.0.0.0:6222 -routes nats://nats:6222"
  echo "-----------------------------------------------------------------"
  echo "$cmd"
  echo "-----------------------------------------------------------------"
  eval $cmd
}

create_service_nats_single() {
  cmd="docker ${remote} service create \
    --name $NATS_NAME \
    --network smartmeter \
    ${EUREKA_WAITER_PARAMS_SERVICE} \
    -e EUREKA_DEBUG=true \
    -e NATS_USERNAME_FILE=/run/secrets/nats_username_secret \
    -e NATS_PASSWORD_FILE=/run/secrets/nats_password_secret \
    -e NATS_CLUSTER_USERNAME_FILE=/run/secrets/nats_cluster_username_secret \
    -e NATS_CLUSTER_PASSWORD_FILE=/run/secrets/nats_cluster_password_secret \
    -p 4222:4222 \
    -p 8222:8222 \
    --secret nats_username_secret \
    --secret nats_password_secret \
    --secret nats_cluster_username_secret \
    --secret nats_cluster_password_secret \
    logimethods/smart-meter:nats-server${postfix} \
      /gnatsd -c gnatsd.conf -m 8222 ${NATS_DEBUG}"
  echo "-----------------------------------------------------------------"
  echo "$cmd"
  echo "-----------------------------------------------------------------"
  eval "$cmd"
}

create_service_nats_client() {
  cmd="docker ${remote} service create \
    --name $NATS_CLIENT_NAME \
    --network smartmeter \
    ${EUREKA_WAITER_PARAMS_SERVICE} \
    -e WAIT_FOR=\"${NATS_NAME}\"
    -e EUREKA_DEBUG=true \
    -e NATS_USERNAME_FILE=/run/secrets/nats_username_secret \
    -e NATS_PASSWORD_FILE=/run/secrets/nats_password_secret \
    -e NATS_SUBJECT=${NATS_CLIENT_SUBJECT} \
    --secret nats_username_secret \
    --secret nats_password_secret \
    logimethods/smart-meter:nats-client${postfix}"
  echo "-----------------------------------------------------------------"
  echo "$cmd"
  echo "-----------------------------------------------------------------"
  eval "$cmd"
}

create_service_app_streaming() {
  cmd="docker ${remote} service create \
    --name app_streaming \
    -e DEPENDS_ON=\"${NATS_NAME},${CASSANDRA_URL}\" \
    -e NATS_USERNAME_FILE=/run/secrets/nats_username_secret \
    -e NATS_PASSWORD_FILE=/run/secrets/nats_password_secret \
    -e SPARK_MASTER_URL=${SPARK_MASTER_URL_STREAMING} \
    -e STREAMING_DURATION=${STREAMING_DURATION} \
    -e CASSANDRA_URL=${CASSANDRA_URL} \
    -e LOG_LEVEL=${APP_STREAMING_LOG_LEVEL} \
    -e TARGETS=${APP_STREAMING_TARGETS} \
    -e SPARK_CORES_MAX=${APP_STREAMING_SPARK_CORES_MAX} \
    --replicas=1 \
    ${ON_MASTER_NODE} \
    --network smartmeter \
    --secret nats_username_secret \
    --secret nats_password_secret \
    logimethods/smart-meter:app-streaming${postfix}  \"com.logimethods.nats.connector.spark.app.SparkMaxProcessor\" \
      \"smartmeter.raw.voltage\" \"smartmeter.extract.voltage.max\" \
      \"Smartmeter MAX Streaming\""

  echo "-----------------------------------------------------------------"
  echo "$cmd"
  echo "-----------------------------------------------------------------"
  eval "$cmd"
}

create_service_prediction_trainer() {
#docker ${remote} pull logimethods/smart-meter:app-streaming
  cmd="docker ${remote} service create \
    --name prediction_trainer \
    -e DEPENDS_ON=\"${NATS_NAME},${CASSANDRA_URL}\" \
    -e WAIT_FOR=\"${HADOOP_NAME}\" \
    -e NATS_USERNAME_FILE=/run/secrets/nats_username_secret \
    -e NATS_PASSWORD_FILE=/run/secrets/nats_password_secret \
    -e SPARK_MASTER_URL=${SPARK_MASTER_URL_STREAMING} \
    -e HDFS_URL=${HDFS_URL} \
    -e CASSANDRA_URL=${CASSANDRA_PREDICTION_URL} \
    -e STREAMING_DURATION=${STREAMING_DURATION} \
    -e LOG_LEVEL=${APP_PREDICTION_LOG_LEVEL} \
    -e SPARK_CORES_MAX=${PREDICTION_TRAINER_SPARK_CORES_MAX} \
    -e ALERT_THRESHOLD=${ALERT_THRESHOLD} \
    --network smartmeter \
    ${ON_MASTER_NODE} \
    --secret nats_username_secret \
    --secret nats_password_secret \
    logimethods/smart-meter:app-streaming${postfix}  \"com.logimethods.nats.connector.spark.app.SparkPredictionTrainer\" \
      \"smartmeter.raw.temperature.forecast.12\" \"smartmeter.extract.voltage.prediction.12\" \
      \"Smartmeter PREDICTION TRAINER\" "
  echo "-----------------------------------------------------------------"
  echo "$cmd"
  echo "-----------------------------------------------------------------"
  eval $cmd
}

create_service_prediction_oracle() {
#docker ${remote} pull logimethods/smart-meter:app-streaming
  cmd="docker ${remote} service create \
    --name prediction_oracle \
    -e DEPENDS_ON=\"${NATS_NAME}\" \
    -e WAIT_FOR=\"${HADOOP_NAME}\" \
    -e NATS_USERNAME_FILE=/run/secrets/nats_username_secret \
    -e NATS_PASSWORD_FILE=/run/secrets/nats_password_secret \
    -e SPARK_MASTER_URL=${SPARK_LOCAL_URL} \
    -e HDFS_URL=${HDFS_URL} \
    -e CASSANDRA_URL=${CASSANDRA_PREDICTION_URL} \
    -e STREAMING_DURATION=${STREAMING_DURATION} \
    -e LOG_LEVEL=${APP_PREDICTION_LOG_LEVEL} \
    -e SPARK_CORES_MAX=${PREDICTION_ORACLE_SPARK_CORES_MAX} \
    -e ALERT_THRESHOLD=${ALERT_THRESHOLD} \
    --network smartmeter \
    --mode global \
    ${ON_WORKER_NODE} \
    --secret nats_username_secret \
    --secret nats_password_secret \
    logimethods/smart-meter:app-streaming${postfix}  \"com.logimethods.nats.connector.spark.app.SparkPredictionOracle\" \
      \"smartmeter.raw.temperature.forecast.12\" \"smartmeter.extract.voltage.prediction.12\" \
      \"Smartmeter PREDICTION ORACLE\" "
  echo "-----------------------------------------------------------------"
  echo "$cmd"
  echo "-----------------------------------------------------------------"
  eval $cmd
}

__run_app_prediction() {
#docker ${remote} pull logimethods/smart-meter:app-streaming
  cmd="docker ${remote} run --rm -d \
    --name app_prediction \
    -e NATS_USERNAME_FILE=/run/secrets/nats_username_secret \
    -e NATS_PASSWORD_FILE=/run/secrets/nats_password_secret \
    -e SPARK_MASTER_URL=${SPARK_MASTER_URL_STREAMING} \
    -e HDFS_URL=${HDFS_URL} \
    -e CASSANDRA_URL=${CASSANDRA_PREDICTION_URL} \
    -e STREAMING_DURATION=${STREAMING_DURATION} \
    -e LOG_LEVEL=${APP_PREDICTION_LOG_LEVEL} \
    -e SPARK_CORES_MAX=${APP_PREDICTION_SPARK_CORES_MAX} \
    -e ALERT_THRESHOLD=${ALERT_THRESHOLD} \
    ${ON_MASTER_NODE} \
    --network smartmeter \
    --secret nats_username_secret \
    --secret nats_password_secret \
    logimethods/smart-meter:app-streaming${postfix}  com.logimethods.nats.connector.spark.app.SparkPredictionProcessor \
      \"smartmeter.raw.temperature.forecast.12\" \"smartmeter.extract.voltage.prediction.12\" \
      \"Smartmeter PREDICTION Streaming\" "
  echo "-----------------------------------------------------------------"
  echo "$cmd"
  echo "-----------------------------------------------------------------"
  eval $cmd
}

run_app-batch() {
  #docker ${remote} pull logimethods/smart-meter:inject
  cmd="docker ${remote} run --rm \
    --name app_batch \
    -e SPARK_MASTER_URL=${SPARK_MASTER_URL_BATCH} \
    -e CASSANDRA_URL=${CASSANDRA_URL} \
    -e APP_BATCH_LOG_LEVEL=${APP_BATCH_LOG_LEVEL} \
    --network smartmeter \
    logimethods/smart-meter:app-batch${postfix}"
  echo "-----------------------------------------------------------------"
  echo "$cmd"
  echo "-----------------------------------------------------------------"
  eval $cmd
}

create_service_app-batch() {
  #docker ${remote} pull logimethods/smart-meter:app-batch
  cmd="docker ${remote} service create \
    --name app-batch \
    -e SPARK_MASTER_URL=${SPARK_MASTER_URL_BATCH} \
    -e LOG_LEVEL=INFO \
    -e CASSANDRA_URL=${CASSANDRA_URL} \
    --network smartmeter \
    --replicas=${replicas} \
    logimethods/smart-meter:app-batch${postfix}"
  echo "-----------------------------------------------------------------"
  echo "$cmd"
  echo "-----------------------------------------------------------------"
  eval $cmd
}

create_service_monitor() {
  #docker ${remote} pull logimethods/smart-meter:monitor
  cmd="docker ${remote} service create \
    --name monitor \
    -e NATS_USERNAME_FILE=/run/secrets/nats_username_secret \
    -e NATS_PASSWORD_FILE=/run/secrets/nats_password_secret \
    --network smartmeter \
    ${ON_MASTER_NODE} \
    --secret nats_username_secret \
    --secret nats_password_secret \
    logimethods/smart-meter:monitor${postfix} \
      \"smartmeter.extract.voltage.>\""
  echo "-----------------------------------------------------------------"
  echo "$cmd"
  echo "-----------------------------------------------------------------"
  eval $cmd
}

create_service_reporter() {
  #docker ${remote} pull logimethods/nats-reporter
  cmd="docker ${remote} service create \
    --name reporter \
    --network smartmeter \
    ${ON_MASTER_NODE} \
    -p 8888:8080 \
    logimethods/nats-reporter"
  echo "-----------------------------------------------------------------"
  echo "$cmd"
  echo "-----------------------------------------------------------------"
  eval $cmd
}

create_service_cassandra-inject() {
  cmd="docker ${remote} service create \
    --name cassandra-inject \
    --network smartmeter \
    --mode global \
    ${ON_WORKER_NODE} \
    -e DEPENDS_ON=\"${NATS_NAME},${CASSANDRA_URL}\" \
    -e NATS_USERNAME_FILE=/run/secrets/nats_username_secret \
    -e NATS_PASSWORD_FILE=/run/secrets/nats_password_secret \
    -e NATS_SUBJECT=\"smartmeter.raw.voltage.data.>\" \
    -e LOG_LEVEL=${CASSANDRA_INJECT_LOG_LEVEL} \
    -e TASK_SLOT={{.Task.Slot}} \
    -e CASSANDRA_INJECT_CONSISTENCY=${CASSANDRA_INJECT_CONSISTENCY} \
    -e CASSANDRA_URL=${CASSANDRA_URL} \
    --secret nats_username_secret \
    --secret nats_password_secret \
    logimethods/smart-meter:cassandra-inject${postfix}"
  echo "-----------------------------------------------------------------"
  echo "$cmd"
  echo "-----------------------------------------------------------------"
  eval $cmd
#   --replicas=${replicas} \
}

create_service_inject() {
  echo "GATLING_USERS_PER_SEC: ${GATLING_USERS_PER_SEC}"
  echo "GATLING_DURATION: ${GATLING_DURATION}"

  #docker ${remote} pull logimethods/smart-meter:inject
  cmd="docker ${remote} service create \
    --name inject \
    --network smartmeter \
    -e DEPENDS_ON=\"${NATS_NAME}\" \
    -e WAIT_FOR=\"${METRICS_GRAPHITE_NAME}\" \
    -e GATLING_TO_NATS_SUBJECT=smartmeter.raw.voltage \
    -e NATS_USERNAME_FILE=/run/secrets/nats_username_secret \
    -e NATS_PASSWORD_FILE=/run/secrets/nats_password_secret \
    -e GATLING_USERS_PER_SEC=${GATLING_USERS_PER_SEC} \
    -e GATLING_DURATION=${GATLING_DURATION} \
    -e STREAMING_DURATION=${STREAMING_DURATION} \
    -e NODE_ID={{.Node.ID}} \
    -e SERVICE_ID={{.Service.ID}} \
    -e SERVICE_NAME={{.Service.Name}} \
    -e SERVICE_LABELS={{.Service.Labels}} \
    -e TASK_ID={{.Task.ID}} \
    -e TASK_NAME={{.Task.Name}} \
    -e TASK_SLOT={{.Task.Slot}} \
    -e RANDOMNESS=${VOLTAGE_RANDOMNESS} \
    -e PREDICTION_LENGTH=${PREDICTION_LENGTH} \
    -e TIME_ROOT=$(date +%s) \
    ${ON_WORKER_NODE} \
    --replicas=${replicas} \
    --secret nats_username_secret \
    --secret nats_password_secret \
    logimethods/smart-meter:inject${postfix} \
      --no-reports -s com.logimethods.smartmeter.inject.NatsInjection"
  echo "-----------------------------------------------------------------"
  echo "$cmd"
  echo "-----------------------------------------------------------------"
  eval $cmd
}

run_inject() {
  echo "GATLING_USERS_PER_SEC: ${GATLING_USERS_PER_SEC}"
  echo "GATLING_DURATION: ${GATLING_DURATION}"
  echo "Replicas: $@"

  #docker ${remote} pull logimethods/smart-meter:inject
  cmd="docker ${remote} run \
    --name inject \
    --network smartmeter \
    -e DEPENDS_ON=\"${NATS_NAME}\" \
    -e GATLING_TO_NATS_SUBJECT=smartmeter.raw.voltage \
    -e NATS_USERNAME_FILE=/run/secrets/nats_username_secret \
    -e NATS_PASSWORD_FILE=/run/secrets/nats_password_secret \
    -e GATLING_USERS_PER_SEC=${GATLING_USERS_PER_SEC} \
    -e GATLING_DURATION=${GATLING_DURATION} \
    -e STREAMING_DURATION=${STREAMING_DURATION} \
    -e TASK_SLOT=1 \
    -e RANDOMNESS=${VOLTAGE_RANDOMNESS} \
    -e PREDICTION_LENGTH=${PREDICTION_LENGTH} \
    --secret nats_username_secret \
    --secret nats_password_secret \
    logimethods/smart-meter:inject${postfix} \
      --no-reports -s com.logimethods.smartmeter.inject.NatsInjection"
  echo "-----------------------------------------------------------------"
  echo "$cmd"
  echo "-----------------------------------------------------------------"
  eval $cmd
}

## TODO EUREKA
run_metrics() {
  # https://bronhaim.wordpress.com/2016/07/24/setup-toturial-for-collecting-metrics-with-statsd-and-grafana-containers/
  run_metrics_graphite
  run_metrics_prometheus
  create_service_influxdb
  run_metrics_grafana
}

run_metrics_graphite() {
  if [ "${postfix}" == "-local" ]
  then
    local_conf="-v ${METRICS_PATH}/graphite/conf:/opt/graphite/conf"
  fi

  cmd="docker ${remote} run -d ${DOCKER_RESTART_POLICY} \
        --network smartmeter \
        --name metrics \
        $local_conf \
        -p 81:80 \
        hopsoft/graphite-statsd:${graphite_statsd_tag}"
  # -v ${METRICS_PATH}/graphite/storage:/opt/graphite/storage\
  # -v ${METRICS_PATH}/statsd:/opt/statsd\
  echo "-----------------------------------------------------------------"
  echo "$cmd"
  echo "-----------------------------------------------------------------"
  eval "$cmd"
}

run_metrics_prometheus() {
  cmd="docker ${remote} run -d ${DOCKER_RESTART_POLICY} \
        --network smartmeter \
        --name ${PROMETHEUS_NAME} \
        -p 9090:9090 \
        logimethods/smart-meter:prometheus${postfix} \
        -storage.local.path=/data -config.file=/etc/prometheus/prometheus.yml -log.level debug"
  echo "-----------------------------------------------------------------"
  echo "$cmd"
  echo "-----------------------------------------------------------------"
  eval "$cmd"
}

create_volume_grafana() {
  ## https://github.com/grafana/grafana-docker#grafana-container-with-persistent-storage-recommended
  #docker ${remote} run -d -v /var/lib/grafana --name grafana-storage --network smartmeter busybox:latest

  cmd="docker ${remote} volume create --name grafana-volume"
  echo "-----------------------------------------------------------------"
  echo "$cmd"
  echo "-----------------------------------------------------------------"
  eval $cmd
}

run_metrics_grafana() {
  cmd="docker ${remote} run -d ${DOCKER_RESTART_POLICY}\
  --network smartmeter \
  --name grafana \
  -p ${METRICS_GRAFANA_WEB_PORT}:3000 \
  -e \"GF_SERVER_ROOT_URL=http://localhost:3000\" \
  -e \"GF_SECURITY_ADMIN_PASSWORD=${GF_SECURITY_ADMIN_PASSWORD}\" \
  -v grafana-volume:/var/lib/grafana \
  grafana/grafana:${grafana_tag}"
  echo "-----------------------------------------------------------------"
  echo "$cmd"
  echo "-----------------------------------------------------------------"
  sh -c "$cmd"
}

create_service_influxdb() {
  cmd="docker ${remote} service create \
    --name ${INFLUXDB_NAME} \
    --network smartmeter \
    ${ON_MASTER_NODE} \
    -e INFLUXDB_ADMIN_ENABLED=true \
    -p 8083:8083 \
    -p 8086:8086 \
    -p 2003:2003 \
    influxdb"
  echo "-----------------------------------------------------------------"
  echo "$cmd"
  echo "-----------------------------------------------------------------"
  eval $cmd
}

update_service_scale() {
  docker ${remote} service scale SERVICE=REPLICAS
}

## TODO EUREKA
run_prometheus_nats_exporter() {
  cmd="docker ${remote} run -d ${DOCKER_RESTART_POLICY} \
        --network smartmeter \
        --name ${PROMETHEUS_NATS_EXPORTER_NAME} \
        ${prometheus_nats_exporter_image}:${prometheus_nats_exporter_tag}${postfix} \
        ${PROMETHEUS_NATS_EXPORTER_FLAGS} \
        ${PROMETHEUS_NATS_EXPORTER_DEBUG} \
        ${PROMETHEUS_NATS_EXPORTER_URLS} "
  echo "-----------------------------------------------------------------"
  echo "$cmd"
  echo "-----------------------------------------------------------------"
  eval "$cmd"
}

## TODO EUREKA
create_service_prometheus_nats_exporter() {
  cmd="docker ${remote} service create \
        --network smartmeter \
        --name ${PROMETHEUS_NATS_EXPORTER_NAME} \
        ${PROMETHEUS_NATS_EXPORTER_SERVICE_MODE} \
        ${prometheus_nats_exporter_image}:${prometheus_nats_exporter_tag}${postfix} \
        ${PROMETHEUS_NATS_EXPORTER_FLAGS} \
        ${PROMETHEUS_NATS_EXPORTER_DEBUG} \
        ${PROMETHEUS_NATS_EXPORTER_URLS} "
  echo "-----------------------------------------------------------------"
  echo "$cmd"
  echo "-----------------------------------------------------------------"
  eval "$cmd"
}

create_service_eureka() {
  cmd="docker ${remote} service create \
    --name ${EUREKA_NAME} \
    --network smartmeter \
    ${ON_MASTER_NODE} \
    --mount type=bind,source=/var/run/docker.sock,destination=/var/run/docker.sock \
    -e FLASK_DEBUG=${FLASK_DEBUG} \
    -p ${FLASK_PORT}:5000 \
    logimethods/eureka${postfix}"
  echo "-----------------------------------------------------------------"
  echo "$cmd"
  echo "-----------------------------------------------------------------"
  eval $cmd
}

__run_telegraf() {
   #if [ "$@" == "docker" ]
  #   then DOCKER_ACCES="-v /var/run/docker.sock:/var/run/docker.sock"
   #fi
   source properties/configuration-telegraf.properties
   source properties/configuration-telegraf-$@.properties
   source properties/configuration-telegraf-debug.properties

   DOCKER_ACCES="-v /var/run/docker.sock:/var/run/docker.sock"

   cmd="docker ${remote} run -d ${DOCKER_RESTART_POLICY}\
     --network smartmeter \
     --name telegraf_$@ \
     ${EUREKA_WAITER_PARAMS_SERVICE} \
     -e SETUP_LOCAL_CONTAINERS=true \
     -e EUREKA_URL=${EUREKA_NAME}
     -e JMX_PASSWORD=$JMX_PASSWORD \
     -e TELEGRAF_DEBUG=$TELEGRAF_DEBUG \
     -e TELEGRAF_QUIET=$TELEGRAF_QUIET \
     -e TELEGRAF_INTERVAL=$TELEGRAF_INTERVAL \
     -e TELEGRAF_INPUT_TIMEOUT=$TELEGRAF_INPUT_TIMEOUT \
     -e WAIT_FOR=$TELEGRAF_WAIT_FOR \
     -e DEPENDS_ON=$TELEGRAF_DEPENDS_ON \
     ${TELEGRAF_ENVIRONMENT_VARIABLES} \
     ${DOCKER_ACCES} \
     --log-driver=json-file \
     logimethods/smart-meter:telegraf${postfix}\
       telegraf --output-filter ${TELEGRAF_OUTPUT_FILTER} -config /etc/telegraf/$@.conf"
    echo "-----------------------------------------------------------------"
    echo "$cmd"
    echo "-----------------------------------------------------------------"
    eval $cmd
}
#-e CASSANDRA_URL=${TELEGRAF_CASSANDRA_URL} \
#-e DOCKER_TARGET_NAME=${TELEGRAF_DOCKER_TARGET_NAME} \
#-e \"TELEGRAF_CASSANDRA_TABLE=$TELEGRAF_CASSANDRA_TABLE\" \
#-e \"TELEGRAF_CASSANDRA_GREP=$TELEGRAF_CASSANDRA_GREP\" \

run_telegraf() {
  source properties/configuration-telegraf.properties
  source properties/configuration-telegraf-$@.properties
  source properties/configuration-telegraf-debug.properties

  DOCKER_ACCES="--mount type=bind,source=/var/run/docker.sock,destination=/var/run/docker.sock"

  cmd="docker ${remote} service create \
    --network smartmeter \
    --name telegraf_$@ \
    ${EUREKA_WAITER_PARAMS_SERVICE} \
    -e SETUP_LOCAL_CONTAINERS=true \
    -e EUREKA_URL=${EUREKA_NAME}
    -e NODE_ID={{.Node.ID}} \
    -e SERVICE_ID={{.Service.ID}} \
    -e SERVICE_NAME={{.Service.Name}} \
    -e SERVICE_LABELS={{.Service.Labels}} \
    -e TASK_ID={{.Task.ID}} \
    -e TASK_NAME={{.Task.Name}} \
    -e TASK_SLOT={{.Task.Slot}} \
    -e JMX_PASSWORD=$JMX_PASSWORD \
    -e TELEGRAF_DEBUG=$TELEGRAF_DEBUG \
    -e TELEGRAF_QUIET=$TELEGRAF_QUIET \
    -e TELEGRAF_INTERVAL=$TELEGRAF_INTERVAL \
    -e TELEGRAF_INPUT_TIMEOUT=$TELEGRAF_INPUT_TIMEOUT \
    -e WAIT_FOR=$TELEGRAF_WAIT_FOR \
    -e DEPENDS_ON=$TELEGRAF_DEPENDS_ON \
    ${TELEGRAF_ENVIRONMENT_VARIABLES} \
    ${DOCKER_ACCES} \
    ${ON_MASTER_NODE} \
    logimethods/smart-meter:telegraf${postfix}\
      telegraf --output-filter ${TELEGRAF_OUTPUT_FILTER} -config /etc/telegraf/$@.conf"
  #     --log-driver=json-file \
  # ${CASSANDRA_MAIN_NAME}
  echo "-----------------------------------------------------------------"
  echo "$cmd"
  echo "-----------------------------------------------------------------"
  eval $cmd
}

create_service_telegraf() {
  source properties/configuration-telegraf.properties
  source properties/configuration-telegraf-$@.properties
  source properties/configuration-telegraf-debug.properties

  DOCKER_ACCES="--mount type=bind,source=/var/run/docker.sock,destination=/var/run/docker.sock"

  cmd="docker ${remote} service create \
    --network smartmeter \
    --name telegraf_$@ \
    ${EUREKA_WAITER_PARAMS_SERVICE} \
    -e SETUP_LOCAL_CONTAINERS=true \
    -e EUREKA_URL=${EUREKA_NAME}
    -e NODE_ID={{.Node.ID}} \
    -e SERVICE_ID={{.Service.ID}} \
    -e SERVICE_NAME={{.Service.Name}} \
    -e SERVICE_LABELS={{.Service.Labels}} \
    -e TASK_ID={{.Task.ID}} \
    -e TASK_NAME={{.Task.Name}} \
    -e TASK_SLOT={{.Task.Slot}} \
    -e JMX_PASSWORD=$JMX_PASSWORD \
    -e TELEGRAF_DEBUG=$TELEGRAF_DEBUG \
    -e TELEGRAF_QUIET=$TELEGRAF_QUIET \
    -e TELEGRAF_INTERVAL=$TELEGRAF_INTERVAL \
    -e TELEGRAF_INPUT_TIMEOUT=$TELEGRAF_INPUT_TIMEOUT \
    -e WAIT_FOR=$TELEGRAF_WAIT_FOR \
    -e DEPENDS_ON=$TELEGRAF_DEPENDS_ON \
    ${TELEGRAF_ENVIRONMENT_VARIABLES} \
    ${DOCKER_ACCES} \
    --mode global \
    logimethods/smart-meter:telegraf${postfix}\
      telegraf --output-filter ${TELEGRAF_OUTPUT_FILTER} -config /etc/telegraf/$@.conf"
  #     --log-driver=json-file \
  # ${CASSANDRA_MAIN_NAME}
  echo "-----------------------------------------------------------------"
  echo "$cmd"
  echo "-----------------------------------------------------------------"
  eval $cmd
}

create_service_telegraf_on_master() {
  source properties/configuration-telegraf.properties
  source properties/configuration-telegraf-$@.properties
  source properties/configuration-telegraf-debug.properties

  DOCKER_ACCES="--mount type=bind,source=/var/run/docker.sock,destination=/var/run/docker.sock"

  cmd="docker ${remote} service create \
    --network smartmeter \
    --name telegraf_$@ \
    ${EUREKA_WAITER_PARAMS_SERVICE} \
    -e SETUP_LOCAL_CONTAINERS=true \
    -e EUREKA_URL=${EUREKA_NAME} \
    -e NODE_ID={{.Node.ID}} \
    -e SERVICE_ID={{.Service.ID}} \
    -e SERVICE_NAME={{.Service.Name}} \
    -e SERVICE_LABELS={{.Service.Labels}} \
    -e TASK_ID={{.Task.ID}} \
    -e TASK_NAME={{.Task.Name}} \
    -e TASK_SLOT={{.Task.Slot}} \
    -e JMX_PASSWORD=$JMX_PASSWORD \
    -e TELEGRAF_DEBUG=$TELEGRAF_DEBUG \
    -e TELEGRAF_QUIET=$TELEGRAF_QUIET \
    -e TELEGRAF_INTERVAL=$TELEGRAF_INTERVAL \
    -e TELEGRAF_INPUT_TIMEOUT=$TELEGRAF_INPUT_TIMEOUT \
    -e WAIT_FOR=$TELEGRAF_WAIT_FOR \
    -e DEPENDS_ON=$TELEGRAF_DEPENDS_ON \
    ${TELEGRAF_ENVIRONMENT_VARIABLES} \
    ${DOCKER_ACCES} \
    ${ON_MASTER_NODE} \
    logimethods/smart-meter:telegraf${postfix}\
      telegraf --output-filter ${TELEGRAF_OUTPUT_FILTER} -config /etc/telegraf/$@.conf"
  #     --log-driver=json-file \
  # ${CASSANDRA_MAIN_NAME}
  echo "-----------------------------------------------------------------"
  echo "$cmd"
  echo "-----------------------------------------------------------------"
  eval $cmd
}

### ZEPPELIN ###

run_zeppelin() {
  cmd="docker ${remote} run -d --rm\
  --network smartmeter \
  --name zeppelin \
  -p ${ZEPPELIN_WEB_PORT}:8080 \
  dylanmei/zeppelin:${zeppelin_tag} sh -c \"./bin/install-interpreter.sh --name cassandra ; ./bin/zeppelin.sh\""
  echo "-----------------------------------------------------------------"
  echo "$cmd"
  echo "-----------------------------------------------------------------"
  sh -c "$cmd"
}

### RUN DOCKER ###

run_image() {
#  name=${1}
#  shift
  echo "docker ${remote} run --network smartmeter ${DOCKER_RESTART_POLICY} $@"
  docker ${remote} run --network smartmeter $@
}

### BUILDS ###

build_inject() {
  pushd dockerfile-inject
  sbt --warn update docker
  popd
}

build_app-streaming() {
  pushd dockerfile-app-streaming
  sbt --warn update docker
  popd
}

build_app-batch() {
  if [ "${postfix}" == "-local" ]
  then
    ./set_properties_to_dockerfile_templates.sh
    pushd dockerfile-app-batch
    echo "docker build -t logimethods/smart-meter:app-batch-DEV ."
    sbt update assembly
    mkdir -p libs
    mv target/scala-*/*.jar libs/
    docker build -t logimethods/smart-meter:app-batch-DEV .
    popd
  else
    echo "docker ${remote} pull logimethods/smart-meter:app-batch${postfix}"
    docker ${remote} pull logimethods/smart-meter:app-batch${postfix}
  fi
}

build_monitor() {
  pushd dockerfile-monitor
  sbt --warn update docker
  popd
}

build_cassandra() {
  ./set_properties_to_dockerfile_templates.sh
  pushd dockerfile-cassandra
  docker build -t logimethods/smart-meter:cassandra-DEV .
  popd
}

build_cassandra-inject() {
  ./set_properties_to_dockerfile_templates.sh
  pushd dockerfile-cassandra-inject
  docker build -t logimethods/smart-meter:cassandra-inject-DEV .
  popd
}

build_nats-server() {
  ./set_properties_to_dockerfile_templates.sh
  pushd dockerfile-nats-server
  docker build -t logimethods/smart-meter:nats-server-DEV .
  popd
}

build_telegraf() {
  ./set_properties_to_dockerfile_templates.sh
  pushd dockerfile-telegraf
  docker build -t logimethods/smart-meter:telegraf-DEV .
  popd
}

### SCALE ###

scale_service() {
  cmd="docker ${remote} service scale $1"
  echo "-----------------------------------------------------------------"
  echo "$cmd"
  echo "-----------------------------------------------------------------"
  eval $cmd
}

### RM ###

rm_service() {
  cmd="docker ${remote} service rm $1"
  echo "-----------------------------------------------------------------"
  echo "$cmd"
  echo "-----------------------------------------------------------------"
  eval $cmd
}

### WAIT ###

wait_service() {
  # http://unix.stackexchange.com/questions/213110/exiting-a-shell-script-with-nested-loops
  echo "Waiting for the $1 Service to Start"
  while :
  do
    echo "--------- $1 ----------"
    docker ${remote} ps | while read -r line
    do
      tokens=( $line )
      full_name=${tokens[1]}
      name=${full_name##*:}
      if [ "$name" == "$1" ] ; then
        exit 1
      fi
    done
    [[ $? != 0 ]] && exit 0

    docker ${remote} service ls | while read -r line
    do
      tokens=( $line )
      name=${tokens[1]}
      if [ "$name" == "$1" ] ; then
        replicas=${tokens[3]}
        actual=${replicas%%/*}
        expected=${replicas##*/}
        #echo "$actual : $expected"
        if [ "$actual" == "$expected" ] ; then
          exit 1
        else
          break
        fi
      fi
    done
    [[ $? != 0 ]] && exit 0

    sleep 2
  done
}

### LOGS ###

logs_service() {
  docker ${remote} logs $(docker ${remote} ps | grep "$1" | rev | cut -d' ' -f1 | rev)
}

### Actual CMD ###

# See http://stackoverflow.com/questions/8818119/linux-how-can-i-run-a-function-from-a-script-in-command-line
echo "!!! $@ !!!"
"$@"

# echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
