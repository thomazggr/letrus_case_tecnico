import logging
from datetime import datetime

from pyspark.sql import functions as F
from pyspark.sql.types import DecimalType

from common import (
    get_secret,
    exec_sql_psycopg2,
    parse_args,
    create_spark,
    write_df_jdbc,
)

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def main(cli_args=None):
    args = parse_args([
        'JOB_NAME',
        'RAW_S3_PATH',
        'PROCESSED_S3_PATH',
        'AURORA_SECRET_ARN',
        'AURORA_DATABASE_NAME'
    ], cli_args)

    spark = create_spark("etl_performance_academica")

    try:
        raw_base = args['RAW_S3_PATH'].rstrip("/")
        processed_base = args['PROCESSED_S3_PATH'].rstrip("/")

        # Leitura dos 3 CSVs
        logger.info(f"Lendo alunos de: {raw_base}/alunos.csv")
        alunos_df = spark.read.option("header", True).csv(raw_base + "/alunos.csv")
        logger.info(f"Lendo escolas de: {raw_base}/escolas.csv")
        escolas_df = spark.read.option("header", True).csv(raw_base + "/escolas.csv")
        logger.info(f"Lendo notas de: {raw_base}/notas.csv")
        notas_df = spark.read.option("header", True).csv(raw_base + "/notas.csv")

        if notas_df.rdd.isEmpty():
            logger.info("Nenhum dado em notas. Abortando job de performance.")
            return

        # Processamento / tipos
        alunos_proc = alunos_df.select(
            alunos_df["id"].cast("long").alias("id"),
            alunos_df["nome_ficticio"],
            alunos_df["idade"].cast("int").alias("idade"),
            alunos_df["genero"]
        )

        escolas_proc = escolas_df.select(
            escolas_df["escola_id"].cast("long").alias("escola_id"),
            escolas_df["nome"],
            escolas_df["rede"],
            escolas_df["regiao"]
        )

        notas_proc = notas_df.select(
            notas_df["aluno_id"].cast("long").alias("aluno_id"),
            notas_df["escola_id"].cast("long").alias("escola_id"),
            notas_df["disciplina"],
            F.col("nota").cast(DecimalType(4, 2)).alias("nota")
        )

        # Join para tabela desnormalizada
        denorm = (
            notas_proc.alias("n")
            .join(alunos_proc.alias("a"), F.col("n.aluno_id") == F.col("a.id"), "left")
            .join(escolas_proc.alias("e"), F.col("n.escola_id") == F.col("e.escola_id"), "left")
            .select(
                F.col("n.aluno_id"),
                F.col("a.nome_ficticio").alias("nome_aluno"),
                F.col("a.idade"),
                F.col("a.genero"),
                F.col("n.escola_id"),
                F.col("e.nome").alias("nome_escola"),
                F.col("e.rede"),
                F.col("e.regiao"),
                F.col("n.disciplina"),
                F.col("n.nota")
            )
        )

        # Escrita Parquet (único path histórico)
        now_str = datetime.now().strftime("run_%Y%m%d_%H%M%S")
        s3_path = processed_base + f"/performance_academica/{now_str}"
        denorm.repartition("disciplina").write.mode("overwrite").parquet(s3_path)
        logger.info(f"Performance acadêmica salva em Parquet: {s3_path}")

        # Staging e upsert incremental no Aurora
        aurora_creds = get_secret(args['AURORA_SECRET_ARN'])
        stg_table = "stg_performance_academica"
        write_df_jdbc(denorm, aurora_creds, args['AURORA_DATABASE_NAME'], stg_table, mode="overwrite")
        logger.info("Staging escrito no Aurora.")

        # Upsert usando chave composta (aluno_id, escola_id, disciplina)
        upsert_sql = f"""
            INSERT INTO public.performance_academica (
                aluno_id, nome_aluno, idade, genero, escola_id, nome_escola, rede, regiao, disciplina, nota
            )
            SELECT aluno_id, nome_aluno, idade, genero, escola_id, nome_escola, rede, regiao, disciplina, nota FROM {stg_table}
            ON CONFLICT (aluno_id, escola_id, disciplina) DO UPDATE SET
                nome_aluno = EXCLUDED.nome_aluno,
                idade = EXCLUDED.idade,
                genero = EXCLUDED.genero,
                nome_escola = EXCLUDED.nome_escola,
                rede = EXCLUDED.rede,
                regiao = EXCLUDED.regiao,
                nota = EXCLUDED.nota;
        """
        exec_sql_psycopg2(aurora_creds, args['AURORA_DATABASE_NAME'], upsert_sql)
        logger.info("Upsert em performance_academica concluído.")

        # Remover staging
        exec_sql_psycopg2(aurora_creds, args['AURORA_DATABASE_NAME'], f"TRUNCATE TABLE {stg_table};")
        exec_sql_psycopg2(aurora_creds, args['AURORA_DATABASE_NAME'], f"DROP TABLE IF EXISTS {stg_table};")
        logger.info("Staging removido.")

        spark.stop()
    except Exception as e:
        logger.error(f"Erro no job etl_performance_academica: {e}")
        raise


if __name__ == "__main__":
    main()