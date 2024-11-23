FROM apache/airflow:2.10.3-python3.10

USER root
# Install Spark

ENV SPARK_VERSION=3.5.0
ENV HADOOP_VERSION=3
ENV SPARK_HOME=/opt/spark
ENV JAVA_HOME /usr/lib/jvm/java-17-openjdk-arm64
ENV SPARK_JARS_IVY=/opt/ivy2

ENV AIRFLOW__CORE__EXECUTOR=LocalExecutor
ENV AIRFLOW__DATABASE__SQL_ALCHEMY_CONN=postgresql+psycopg2://airflow:airflow@postgres/airflow
ENV AIRFLOW__CELERY__RESULT_BACKEND=db+postgresql://airflow:airflow@postgres/airflow
ENV AIRFLOW__CELERY__BROKER_URL=redis://:@redis:6379/0
ENV AIRFLOW__CORE__FERNET_KEY=''
ENV AIRFLOW__CORE__DAGS_ARE_PAUSED_AT_CREATION='false'
ENV AIRFLOW__CORE__LOAD_EXAMPLES='false'
ENV AIRFLOW__API__AUTH_BACKENDS='airflow.api.auth.backend.basic_auth,airflow.api.auth.backend.session'
ENV AIRFLOW__SCHEDULER__ENABLE_HEALTH_CHECK='true'



RUN mkdir -p /opt/ivy2 
RUN mkdir -p /opt/airflow/scripts/


RUN apt-get update && \
    apt-get install -y openjdk-17-jdk build-essential libssl-dev zlib1g-dev procps\
    libbz2-dev libreadline-dev libsqlite3-dev curl git libncursesw5-dev xz-utils \
    tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev neovim zoxide fzf zsh \
    stow golang fd-find silversearcher-ag python3-pip python3-venv unzip pip \
    ripgrep  gcc python3-dev wget && \
    wget -qO- https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz | tar -xz -C /opt/ && \
    mv /opt/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} $SPARK_HOME && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


RUN chmod 777 /opt/ivy2/ 
RUN chmod 777 /opt/airflow/scripts/

ENV PATH=$JAVA_HOME/bin:$SPARK_HOME/bin:$PATH


COPY ./src/scripts/init-airflow-spark-connection.py /opt/airflow/scripts/

# Copy pyproject.toml and pdm.lock files
COPY ./pyproject.toml /opt/airflow/

USER airflow

# Install Python dependencies using pdm
RUN pip install pdm
RUN cd /opt/airflow && pdm install
