import sys
import json
import boto3
import logging
from pyspark.sql import SparkSession

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def get_secret(secret_arn):
    logger.info(f"Buscando secret do ARN: {secret_arn}")
    client = boto3.client('secretsmanager')
    try:
        response = client.get_secret_value(SecretId=secret_arn)
        secret = json.loads(response['SecretString'])
        logger.info("Secret obtido com sucesso.")
        return secret
    except Exception as e:
        logger.error(f"Erro ao buscar secret: {e}")
        raise

def parse_args(expected_keys, cli_args=None):
    args = {}
    arr = cli_args if cli_args is not None else sys.argv[1:]
    for a in arr:
        if a.startswith("--"):
            if "=" in a:
                k, v = a[2:].split("=", 1)
                args[k] = v
            else:
                args[a[2:]] = ""
    missing = [k for k in expected_keys if k not in args]
    if missing:
        raise ValueError(f"Missing required args: {missing}")
    return args

def create_spark(app_name):
    spark = SparkSession.builder \
        .appName(app_name) \
        .getOrCreate()
    return spark

def write_df_jdbc(df, aurora_creds, db_name, table, mode="append"):
    url = f"jdbc:postgresql://{aurora_creds['host']}:{aurora_creds['port']}/{db_name}"
    props = {
        "user": aurora_creds['username'],
        "password": aurora_creds['password'],
        "driver": "org.postgresql.Driver"
    }
    df.write.mode(mode).jdbc(url=url, table=table, properties=props)

def exec_sql_psycopg2(aurora_creds, db_name, sql, params=None):
    import psycopg2
    conn = None
    try:
        conn = psycopg2.connect(
            host=aurora_creds['host'],
            port=aurora_creds['port'],
            user=aurora_creds['username'],
            password=aurora_creds['password'],
            dbname=db_name
        )
        conn.autocommit = True
        cur = conn.cursor()
        cur.execute(sql, params or ())
        cur.close()
    finally:
        if conn:
            conn.close()
