from airflow import settings
from airflow.models import Connection
from airflow.utils.db import provide_session

@provide_session
def create_connection(session=None):
    conn_id = 'spark_default'
    conn_type = 'spark'
    host = 'spark://spark-master:7077'
    extra = '{"queue": "default"}'

    # Check if the connection already exists
    existing_conn = session.query(Connection).filter(Connection.conn_id == conn_id).first()
    if existing_conn:
        print(f"Connection {conn_id} already exists")
        return

    # Create the new connection
    new_conn = Connection(
        conn_id=conn_id,
        conn_type=conn_type,
        host=host,
        extra=extra
    )

    # Add the new connection to the session and commit
    session.add(new_conn)
    session.commit()
    print(f"Connection {conn_id} created successfully")

# Call the function to create the connection
create_connection()
